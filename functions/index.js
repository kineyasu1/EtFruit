const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");
const cors = require("cors")({ origin: true });
const crypto = require("crypto");

admin.initializeApp();

// Read Chapa Keys from Firebase environment config.
// Set these values via command line:
// firebase functions:config:set chapa.secret="CHAPA_SEC-..." chapa.webhook_secret="your_webhook_secret"
const CHAPA_SECRET_KEY = process.env.CHAPA_SECRET || functions.config().chapa?.secret || "CHAPA_SEC-test-key";
const CHAPA_WEBHOOK_SECRET = process.env.CHAPA_WEBHOOK_SECRET || functions.config().chapa?.webhook_secret || "chapa_webhook_secret_key";

/**
 * HTTP Endpoint to initiate payment with Chapa.
 * Takes transaction details and returns checkout_url.
 */
exports.initiatePayment = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    if (req.method !== "POST") {
      return res.status(400).send("Only POST requests allowed");
    }

    try {
      const { txId, amount, email, buyerId, sellerId, listingId, title } = req.body;

      if (!txId || !amount || !buyerId || !sellerId || !listingId) {
        return res.status(400).json({ status: "fail", message: "Missing parameters" });
      }

      // Configure Chapa initialize payload
      // In production, callback_url should point to the chapaWebhook function URL.
      const chapaPayload = {
        amount: amount.toString(),
        currency: "ETB",
        email: email || "buyer@farmlink.com",
        first_name: "Buyer",
        last_name: buyerId,
        tx_ref: txId,
        callback_url: `https://${req.headers.host}/${process.env.GCLOUD_PROJECT}/us-central1/chapaWebhook`,
        customization: {
          title: title || "FarmLink Marketplace",
          description: `Direct Payment for listing ${listingId}`,
        },
        meta: {
          buyerId,
          sellerId,
          listingId,
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
 * Webhook callback endpoint hit by Chapa on successful/failed transaction.
 * Validates the HMAC signature and updates Firestore transaction & chat records.
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
    // Validate signature
    const hash = crypto
      .createHmac("sha256", CHAPA_WEBHOOK_SECRET)
      .update(JSON.stringify(req.body))
      .digest("hex");

    if (hash !== signature) {
      console.warn("Signature mismatch on webhook callback!");
      return res.status(401).send("Invalid signature signature");
    }

    const event = req.body;
    const txId = event.tx_ref;
    const status = event.status; // 'success' or 'failed'

    console.log(`Received Webhook Event for Tx: ${txId}, Status: ${status}`);

    const db = admin.firestore();
    const txRef = db.collection("transactions").doc(txId);
    const txDoc = await txRef.get();

    if (!txDoc.exists) {
      console.warn(`Transaction document ${txId} not found in Firestore.`);
      return res.status(404).send("Transaction not found");
    }

    const txData = txDoc.data();
    
    // Check if already processed
    if (txData.status === "completed") {
      return res.status(200).send("Webhook already processed");
    }

    if (status === "success") {
      // 1. Update Transaction to completed
      await txRef.update({
        status: "completed",
        gatewayReferenceId: event.reference || "",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 2. Write receipt message to the in-app chat thread
      const chatId = `${txData.listingId}_${txData.buyerId}_${txData.sellerId}`;
      const messageId = `msg_receipt_${Date.now()}`;
      
      const receiptMessage = {
        id: messageId,
        senderId: "system",
        text: `🔔 PAYMENT CONFIRMED RECEIPT:\nAmount: ${txData.amount} ETB\nPayment Method: ${txData.paymentMethod}\nTransaction ID: ${txData.id}`,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      await db
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .doc(messageId)
        .set(receiptMessage);

      await db.collection("chats").doc(chatId).update({
        lastMessageText: `Payment Confirmed: ${txData.amount} ETB`,
        lastMessageSenderId: "system",
        lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Transaction ${txId} successfully updated to completed.`);
    } else {
      await txRef.update({
        status: "failed",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`Transaction ${txId} updated to failed.`);
    }

    return res.status(200).send("Webhook handled successfully");
  } catch (error) {
    console.error("Webhook processing error:", error);
    return res.status(500).send("Internal Server Error");
  }
});
