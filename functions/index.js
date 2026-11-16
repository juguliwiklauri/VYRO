
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();

const db = getFirestore();

const PLATFORM_FEE_PERCENT = 5;

// საჩუქრების ფასები განისაზღვრება მხოლოდ სერვერზე.
const GIFTS = {
  rose: { name: "Rose", coins: 10 },
  heart: { name: "Heart", coins: 50 },
  diamond: { name: "Diamond", coins: 100 },
  rocket: { name: "Rocket", coins: 500 },
};

exports.sendLiveGift = onCall(
  { region: "europe-west3" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "საჩუქრის გასაგზავნად საჭიროა ავტორიზაცია."
      );
    }

    const senderUid = request.auth.uid;
    const { liveId, giftId, requestId } = request.data || {};

    if (
      typeof liveId !== "string" ||
      liveId.length < 1 ||
      liveId.length > 128 ||
      typeof giftId !== "string" ||
      typeof requestId !== "string" ||
      !/^[a-zA-Z0-9_-]{12,80}$/.test(requestId)
    ) {
      throw new HttpsError(
        "invalid-argument",
        "მონაცემები არასწორია."
      );
    }

    const gift = GIFTS[giftId];

    if (!gift) {
      throw new HttpsError(
        "invalid-argument",
        "ასეთი საჩუქარი არ არსებობს."
      );
    }

    const liveRef = db.collection("lives").doc(liveId);
    const senderRef = db.collection("users").doc(senderUid);
    const transactionRef = db
      .collection("giftTransactions")
      .doc(`${senderUid}_${requestId}`);

    const platformRef = db
      .collection("platformStats")
      .doc("turbo");

    try {
      return await db.runTransaction(async (transaction) => {
        const liveSnapshot = await transaction.get(liveRef);
        const senderSnapshot = await transaction.get(senderRef);
        const previousGift = await transaction.get(transactionRef);

        if (previousGift.exists) {
          throw new HttpsError(
            "already-exists",
            "ეს საჩუქარი უკვე გაგზავნილია."
          );
        }

        if (!liveSnapshot.exists || !senderSnapshot.exists) {
          throw new HttpsError(
            "not-found",
            "LIVE ან მომხმარებელი ვერ მოიძებნა."
          );
        }

        const liveData = liveSnapshot.data();
        const senderData = senderSnapshot.data();

        const receiverUid = liveData.hostUid;

        if (
          liveData.status !== "live" ||
          typeof receiverUid !== "string"
        ) {
          throw new HttpsError(
            "failed-precondition",
            "ეს LIVE ამჟამად აქტიური არ არის."
          );
        }

        if (receiverUid === senderUid) {
          throw new HttpsError(
            "failed-precondition",
            "საკუთარ თავს საჩუქარს ვერ გაუგზავნი."
          );
        }

        const receiverRef = db.collection("users").doc(receiverUid);
        const receiverSnapshot = await transaction.get(receiverRef);
        const platformSnapshot = await transaction.get(platformRef);

        if (!receiverSnapshot.exists) {
          throw new HttpsError(
            "not-found",
            "LIVE-ის ავტორი ვერ მოიძებნა."
          );
        }

        const walletCoins = senderData.walletCoins;

        if (
          !Number.isSafeInteger(walletCoins) ||
          walletCoins < gift.coins
        ) {
          throw new HttpsError(
            "failed-precondition",
            "მონეტები საკმარისი არ არის."
          );
        }

        const feeCoins = Math.floor(
          gift.coins * PLATFORM_FEE_PERCENT / 100
        );

        const creatorCoins = gift.coins - feeCoins;

        transaction.update(senderRef, {
          walletCoins: walletCoins - gift.coins,
        });

        transaction.update(receiverRef, {
          creatorEarningsCoins: FieldValue.increment(creatorCoins),
        });

        transaction.set(platformRef, {
          platformFeeCoins: FieldValue.increment(feeCoins),
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });

        transaction.create(transactionRef, {
          liveId,
          senderUid,
          receiverUid,
          giftId,
          giftName: gift.name,
          totalCoins: gift.coins,
          creatorCoins,
          platformFeeCoins: feeCoins,
          feePercent: PLATFORM_FEE_PERCENT,
          createdAt: FieldValue.serverTimestamp(),
        });

        return {
          success: true,
          giftName: gift.name,
          totalCoins: gift.coins,
          creatorCoins,
          platformFeeCoins: feeCoins,
        };
      });
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }

      console.error("sendLiveGift failed:", error);

      throw new HttpsError(
        "internal",
        "საჩუქრის გაგზავნა ვერ მოხერხდა."
      );
    }
  }
);
