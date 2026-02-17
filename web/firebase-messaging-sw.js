importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.1/firebase-messaging.js");

firebase.initializeApp({
  apiKey: "AIzaSyB7yN1-LVdNqMksmHj8gVEJLGtNvvD6c1U",
  authDomain: "fama-7db84.firebaseapp.com",
  projectId: "fama-7db84",
  storageBucket: "fama-7db84.firebasestorage.app",
  messagingSenderId: "888957940076",
  appId: "1:888957940076:web:e739d75fd1630e74ca8349",
  measurementId: "G-X5WNYB3DZ6"
});

const messaging = firebase.messaging();

messaging.setBackgroundMessageHandler(function (payload) {
    const promiseChain = clients
        .matchAll({
            type: "window",
            includeUncontrolled: true
        })
        .then(windowClients => {
            for (let i = 0; i < windowClients.length; i++) {
                const windowClient = windowClients[i];
                windowClient.postMessage(payload);
            }
        })
        .then(() => {
            const title = payload.notification.title;
            const options = {
                body: payload.notification.body
              };
            return registration.showNotification(title, options);
        });
    return promiseChain;
});
self.addEventListener('notificationclick', function (event) {
    console.log('notification received: ', event)
});