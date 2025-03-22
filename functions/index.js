const {onCall} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();

// 🔹 Désactiver AppCheck et Auth obligatoire
setGlobalOptions({enforceAppCheck: false});

exports.sendFriendRequestNotification = onCall(
    {
      enforceAppCheck: false,
      allowUnauthenticated: true,
    },
    async (request) => {
      console.log("Données reçues :", request.data);
      console.log("📥 Requête reçue :", JSON.stringify(request.data));

      const {token, senderName} = request.data;

      if (!token || !senderName) {
        console.error("❌ Données manquantes : token ou senderName");
        return {success: false, error: "Données manquantes"};
      }

      const message = {
        token: token,
        notification: {
          title: "Nouvelle demande d'ami",
          body: `${senderName} t'a envoyé une demande d'ami.`,
        },
        data: {
          type: "friend_request",
        },
      };

      try {
        await admin.messaging().send(message);
        console.log("✅ Notification envoyée avec succès !");
        return {success: true};
      } catch (error) {
        console.error("❌ Erreur lors de l'envoi de la notification :", error);
        return {success: false, error: error.message};
      }
    },
);
