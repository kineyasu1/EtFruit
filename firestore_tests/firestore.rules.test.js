const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');

let testEnv;

describe('Firestore Security Rules', () => {
  before(async () => {
    // Initialize test environment with firestore.rules
    const rulesPath = path.resolve(__dirname, '../firestore.rules');
    const rules = fs.readFileSync(rulesPath, 'utf8');
    
    testEnv = await initializeTestEnvironment({
      projectId: 'et-fruit-test',
      firestore: {
        rules: rules,
      },
    });
  });

  after(async () => {
    await testEnv.cleanup();
  });

  afterEach(async () => {
    await testEnv.clearFirestore();
  });

  it('rejects client update to set status to success on a transaction', async () => {
    const context = testEnv.authenticatedContext('buyer_123');
    const db = context.firestore();
    
    // Seed initial document bypassing rules
    await testEnv.withSecurityRulesDisabled(async (adminContext) => {
      const adminDb = adminContext.firestore();
      await adminDb.collection('transactions').doc('tx_123').set({
        buyerId: 'buyer_123',
        sellerId: 'seller_123',
        amount: 100,
        status: 'pending'
      });
    });

    const txRef = db.collection('transactions').doc('tx_123');

    // Attempt client update to success (should be rejected)
    await assertFails(
      txRef.update({
        status: 'success'
      })
    );

    // Attempt client update to failed (should succeed)
    await assertSucceeds(
      txRef.update({
        status: 'failed'
      })
    );
  });
});
