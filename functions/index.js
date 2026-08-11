const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");
const cors = require("cors")({ origin: true });
const crypto = require("crypto");

admin.initializeApp();

// Read Chapa Keys from Firebase environment config or env vars
const CHAPA_SECRET_KEY = process.env.CHAPA_SECRET || functions.config().chapa?.secret || "PLACEHOLDER_CHAPA_SECRET_KEY";
const CHAPA_WEBHOOK_SECRET = process.env.CHAPA_WEBHOOK_SECRET || functions.config().chapa?.webhook_secret || "PLACEHOLDER_CHAPA_WEBHOOK_SECRET";

/**
 * 1. HTTP Endpoint to initiate payment with Chapa.
 * Accepts orderId (txId), sellerPrice (or amount), commissionRate (default 5%).
 * Computes: totalAmount = sellerPrice + commissionAmount
 * Saves Order & Transaction records in Firestore, then initializes Chapa checkout link.
 */
exports.initiatePayment = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    if (req.method !== "POST") {
      return res.status(400).send("Only POST requests allowed");
    }

    try {
      const { txId, orderId: inputOrderId, amount, sellerPrice, commissionRate, email, buyerId, sellerId, listingId, title } = req.body;
      const orderId = inputOrderId || txId;

      if (!orderId || (!amount && !sellerPrice) || !buyerId || !sellerId || !listingId) {
        return res.status(400).json({ status: "fail", message: "Missing required order/transaction parameters" });
      }

      const sellerPriceNum = Number(sellerPrice || amount || 0);
      const commRateNum = Number(commissionRate !== undefined ? commissionRate : 0.05);
      const commissionAmount = Number((sellerPriceNum * commRateNum).toFixed(2));
      const totalAmount = Number((sellerPriceNum + commissionAmount).toFixed(2));

      const db = admin.firestore();

      // Create/update Firestore Order record
      const orderRef = db.collection("orders").doc(orderId);
      await orderRef.set({
        id: orderId,
        buyerId,
        sellerId,
        listingId,
        listingTitle: title || "Agricultural Listing",
        sellerPrice: sellerPriceNum,
        commissionRate: commRateNum,
        commissionAmount,
        totalAmount,
        status: "Pending Payment",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      // Create/update Firestore Transaction record
      const txRef = db.collection("transactions").doc(orderId);
      await txRef.set({
        id: orderId,
        orderId,
        buyerId,
        sellerId,
        listingId,
        listingTitle: title || "Agricultural Listing",
        sellerPrice: sellerPriceNum,
        commissionRate: commRateNum,
        commissionAmount,
        amount: totalAmount,
        currency: "ETB",
        status: "pending",
        gatewayReferenceId: "",
        checkoutUrl: "",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      // Determine dynamic callback URL
      let callbackUrl;
      if (req.headers.host.includes("localhost") || req.headers.host.includes("127.0.0.1") || req.headers.host.includes("10.0.2.2")) {
        callbackUrl = `http://${req.headers.host}/${process.env.GCLOUD_PROJECT}/us-central1/chapaWebhook`;
      } else {
        callbackUrl = `https://${req.headers.host}/chapaWebhook`;
      }

      const chapaPayload = {
        amount: totalAmount.toString(),
        currency: "ETB",
        email: email || "buyer@agrimarket.com",
        first_name: "Buyer",
        last_name: buyerId,
        tx_ref: orderId,
        callback_url: callbackUrl,
        customization: {
          title: title || "AgriMarket Marketplace",
          description: `Order ${orderId} (Item: ${sellerPriceNum} ETB + App Fee: ${commissionAmount} ETB)`,
        },
        meta: {
          orderId,
          buyerId,
          sellerId,
          listingId,
          sellerPrice: sellerPriceNum,
          commissionAmount,
          totalAmount,
        }
      };

      const response = await axios.post(
        "https://api.chapa.co/v1/transaction/initialize",
        chapaPayload,
        {
          headers: {
            Authorization: `Bearer ${CHAPA_SECRET_KEY}`,
            "Content-Type": "application/json",
          },
        }
      );

      if (response.data && response.data.data && response.data.data.checkout_url) {
        const checkoutUrl = response.data.data.checkout_url;
        await txRef.update({ checkoutUrl });
        await orderRef.update({ checkoutUrl });
      }

      return res.status(200).json(response.data);
    } catch (error) {
      console.error("Chapa Initialization Error:", error.response ? error.response.data : error.message);
      return res.status(500).json({
        status: "fail",
        message: error.response ? error.response.data.message : error.message,
      });
    }
  });
});

/**
 * 2. Webhook callback endpoint hit by Chapa on successful/failed transaction.
 * Validates HMAC signature.
 * On Success:
 * - Marks Order as "Payment Confirmed"
 * - Marks Transaction as "completed"
 * - Creates Pending Payout Record for seller (status: "pending_delivery")
 */
exports.chapaWebhook = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    return res.status(400).send("Only POST requests allowed");
  }

  const signature = req.headers["x-chapa-signature"];
  if (!signature) {
    return res.status(401).send("No signature provided");
  }

  try {
    const hash = crypto
      .createHmac("sha256", CHAPA_WEBHOOK_SECRET)
      .update(req.rawBody)
      .digest("hex");

    if (hash !== signature) {
      console.warn("Signature mismatch on webhook callback!");
      return res.status(401).send("Invalid signature");
    }

    const event = req.body;
    const orderId = event.tx_ref;
    const status = event.status; // 'success' or 'failed'

    console.log(`Received Webhook Event for Order: ${orderId}, Status: ${status}`);

    const db = admin.firestore();
    const txRef = db.collection("transactions").doc(orderId);
    const orderRef = db.collection("orders").doc(orderId);

    const txDoc = await txRef.get();
    const orderDoc = await orderRef.get();

    if (!txDoc.exists && !orderDoc.exists) {
      console.warn(`Order/Transaction document ${orderId} not found in Firestore.`);
      return res.status(404).send("Order/Transaction not found");
    }

    const txData = txDoc.exists ? txDoc.data() : {};
    const orderData = orderDoc.exists ? orderDoc.data() : {};

    if (txData.status === "completed" || orderData.status === "Payment Confirmed") {
      return res.status(200).send("Webhook already processed");
    }

    if (status === "success") {
      // Mark Transaction completed
      await txRef.update({
        status: "completed",
        gatewayReferenceId: event.reference || "",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Mark Order as "Payment Confirmed"
      await orderRef.update({
        status: "Payment Confirmed",
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Create Pending Payout Record for Seller
      const payoutId = `payout_${orderId}`;
      const payoutRef = db.collection("payouts").doc(payoutId);
      
      const totalAmount = txData.amount || orderData.totalAmount || 0;
      const sellerPrice = txData.sellerPrice || orderData.sellerPrice || totalAmount;
      const commissionAmount = txData.commissionAmount || orderData.commissionAmount || 0;

      await payoutRef.set({
        id: payoutId,
        orderId: orderId,
        sellerId: txData.sellerId || orderData.sellerId,
        buyerId: txData.buyerId || orderData.buyerId,
        totalAmount,
        sellerPrice,
        commissionAmount,
        sellerAmount: 0, // Calculated upon delivery confirmation
        status: "pending_delivery",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Write receipt message to the in-app chat thread
      const chatId = `${txData.listingId || orderData.listingId}_${txData.buyerId || orderData.buyerId}_${txData.sellerId || orderData.sellerId}`;
      const messageId = `msg_receipt_${Date.now()}`;
      
      const receiptMessage = {
        id: messageId,
        senderId: "system",
        text: `🔔 PAYMENT CONFIRMED:\nOrder ID: ${orderId}\nTotal Paid: ${totalAmount} ETB\nSeller Payout Pending Delivery Confirmation.`,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      await db
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .doc(messageId)
        .set(receiptMessage);

      // Send push notifications
      try {
        const buyerId = txData.buyerId || orderData.buyerId;
        const sellerId = txData.sellerId || orderData.sellerId;

        if (buyerId) {
          const buyerDoc = await db.collection("users").doc(buyerId).get();
          if (buyerDoc.exists && buyerDoc.data().fcmToken) {
            await admin.messaging().send({
              token: buyerDoc.data().fcmToken,
              notification: {
                title: "Payment Confirmed",
                body: `Your payment of ${totalAmount} ETB for Order #${orderId} is confirmed.`,
              },
              data: { type: "order", orderId }
            });
          }
        }

        if (sellerId) {
          const sellerDoc = await db.collection("users").doc(sellerId).get();
          if (sellerDoc.exists && sellerDoc.data().fcmToken) {
            await admin.messaging().send({
              token: sellerDoc.data().fcmToken,
              notification: {
                title: "New Order Paid",
                body: `Payment received for Order #${orderId}. Pending delivery confirmation for payout!`,
              },
              data: { type: "order", orderId }
            });
          }
        }
      } catch (fcmErr) {
        console.error("Webhook FCM Error:", fcmErr.message);
      }
    } else {
      await txRef.update({
        status: "failed",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      await orderRef.update({
        status: "Payment Failed",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    return res.status(200).send("Webhook handled successfully");
  } catch (error) {
    console.error("Webhook processing error:", error);
    return res.status(500).send("Internal Server Error");
  }
});

/**
 * 3. Cloud Function triggered on Order status update.
 * On Delivery Confirmation (status === "delivered"):
 * - Calculates seller_amount = total_amount - commission_amount
 * - Marks Payout record as "ready_for_payout"
 */
exports.onOrderStatusUpdated = functions.firestore
  .document("orders/{orderId}")
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();

    if (beforeData.status === afterData.status) {
      return null;
    }

    const db = admin.firestore();
    const orderId = context.params.orderId;

    try {
      // Check for delivery confirmation
      const isDelivered = afterData.status === "delivered" || afterData.status === "Delivered" || afterData.status === "Completed";
      
      if (isDelivered) {
        const payoutId = `payout_${orderId}`;
        const payoutRef = db.collection("payouts").doc(payoutId);
        const payoutDoc = await payoutRef.get();

        if (payoutDoc.exists) {
          const payoutData = payoutDoc.data();
          if (payoutData.status === "pending_delivery") {
            const totalAmount = payoutData.totalAmount || afterData.totalAmount || 0;
            const commissionAmount = payoutData.commissionAmount || afterData.commissionAmount || 0;
            const sellerAmount = Number((totalAmount - commissionAmount).toFixed(2));

            await payoutRef.update({
              sellerAmount,
              status: "ready_for_payout",
              deliveryConfirmedAt: admin.firestore.FieldValue.serverTimestamp(),
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            console.log(`Order ${orderId} delivered. Payout ${payoutId} marked ready_for_payout (Seller Amount: ${sellerAmount} ETB).`);

            // Notify Seller
            const sellerDoc = await db.collection("users").doc(afterData.sellerId).get();
            if (sellerDoc.exists && sellerDoc.data().fcmToken) {
              await admin.messaging().send({
                token: sellerDoc.data().fcmToken,
                notification: {
                  title: "Payout Ready!",
                  body: `Order #${orderId} delivered. ${sellerAmount} ETB is marked ready for payout!`,
                },
                data: { type: "payout", orderId }
              });
            }
          }
        }
      }

      // Notify Buyer on status change
      const buyerId = afterData.buyerId;
      if (buyerId) {
        const buyerDoc = await db.collection("users").doc(buyerId).get();
        if (buyerDoc.exists && buyerDoc.data().fcmToken) {
          await admin.messaging().send({
            token: buyerDoc.data().fcmToken,
            notification: {
              title: "Order Status Update",
              body: `Your order for "${afterData.listingTitle || 'product'}" is now "${afterData.status}".`,
            },
            data: { type: "order", orderId }
          });
        }
      }
    } catch (error) {
      console.error("FCM Order Status update failed:", error);
    }
    return null;
  });

/**
 * 4. Batch Payout Cloud Function (HTTPS / Scheduled trigger).
 * Queries all payouts with status "ready_for_payout".
 * Aggregates payouts per seller and marks them as "completed".
 */
exports.processBatchPayouts = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    try {
      const db = admin.firestore();
      const snapshot = await db.collection("payouts")
        .where("status", "==", "ready_for_payout")
        .get();

      if (snapshot.empty) {
        return res.status(200).json({ status: "success", message: "No pending payouts ready for batch processing." });
      }

      const batch = db.batch();
      const sellerPayoutsMap = {};
      let count = 0;

      snapshot.docs.forEach((doc) => {
        const payout = doc.data();
        const sellerId = payout.sellerId;

        if (!sellerPayoutsMap[sellerId]) {
          sellerPayoutsMap[sellerId] = 0;
        }
        sellerPayoutsMap[sellerId] += payout.sellerAmount || 0;

        batch.update(doc.ref, {
          status: "completed",
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        count++;
      });

      await batch.commit();

      // Dispatch FCM Push Notifications to Sellers
      for (const [sellerId, totalDisbursed] of Object.entries(sellerPayoutsMap)) {
        try {
          const sellerDoc = await db.collection("users").doc(sellerId).get();
          if (sellerDoc.exists && sellerDoc.data().fcmToken) {
            await admin.messaging().send({
              token: sellerDoc.data().fcmToken,
              notification: {
                title: "Payout Disbursed",
                body: `Your batch payout of ${totalDisbursed.toFixed(2)} ETB has been disbursed!`,
              },
              data: { type: "payout_batch" }
            });
          }
        } catch (err) {
          console.error(`FCM Payout notification error for seller ${sellerId}:`, err);
        }
      }

      console.log(`Successfully processed ${count} payouts for ${Object.keys(sellerPayoutsMap).length} sellers.`);
      return res.status(200).json({
        status: "success",
        processedCount: count,
        sellersCount: Object.keys(sellerPayoutsMap).length,
        sellerTotals: sellerPayoutsMap,
      });
    } catch (error) {
      console.error("Batch Payout Processing Error:", error);
      return res.status(500).json({ status: "fail", message: error.message });
    }
  });
});

/**
 * Cloud Function triggered on new chat message.
 */
exports.onMessageCreated = functions.firestore
  .document("chats/{chatId}/messages/{messageId}")
  .onCreate(async (snap, context) => {
    const message = snap.data();
    if (message.senderId === "system") return null;

    const chatId = context.params.chatId;
    const db = admin.firestore();

    try {
      const chatDoc = await db.collection("chats").doc(chatId).get();
      if (!chatDoc.exists) return null;

      const chatData = chatDoc.data();
      const participantIds = chatData.participantIds || [];
      const recipientId = participantIds.find(id => id !== message.senderId);
      if (!recipientId) return null;

      const recipientDoc = await db.collection("users").doc(recipientId).get();
      if (!recipientDoc.exists) return null;

      const fcmToken = recipientDoc.data().fcmToken;
      if (fcmToken) {
        const senderDoc = await db.collection("users").doc(message.senderId).get();
        const senderName = senderDoc.exists ? (senderDoc.data().name || "User") : "User";

        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: senderName,
            body: message.text,
          },
          data: {
            type: "chat",
            chatId: chatId,
            otherUserName: senderName,
          },
        });
      }
    } catch (error) {
      console.error("FCM Message trigger failed:", error);
    }
    return null;
  });
