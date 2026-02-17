# Redirection paiement Wave vers l'app Fama

## Problème

Après un paiement Wave réussi, l'utilisateur était redirigé vers la page web :
```
https://aliceblue-herring-852976.hostingersite.com/payment-success?status=success&payment_id=...
```

L'utilisateur restait dans le navigateur (ou dans l'app Wave) au lieu de revenir dans Fama.

**IMPORTANT** : Quand l'utilisateur paie dans l'app Wave ou dans le navigateur, le callback `payment-success` s'affiche dans ce contexte externe. La seule façon de ramener l'utilisateur dans Fama est que le backend redirige vers le deep link.

## Solution

L'application Fama gère désormais les **deep links** pour le callback de paiement. Le backend doit rediriger vers un deep link qui ouvre l'app directement.

### Deep link à utiliser

```
Fama://stackfood.com/payment-callback?status=success&order_id=ORDER_ID
```

ou en cas d'échec :

```
Fama://stackfood.com/payment-callback?status=fail&order_id=ORDER_ID
```

### Paramètres requis

| Paramètre | Description |
|-----------|-------------|
| `status` | `success` ou `fail` |
| `order_id` | ID de la commande (référence interne de l'app) |

### Modification backend requise

Sur la page **payment-success** (et **payment-fail**), au lieu d'afficher du contenu HTML, effectuer une **redirection immédiate** (HTTP 302 ou meta refresh) vers le deep link.

#### Exemple PHP (Laravel)

```php
// Dans le contrôleur ou la vue payment-success
$orderId = $payment->order_id; // Récupérer depuis payment_id
$status = 'success'; // ou 'fail' pour payment-fail

$deepLink = "Fama://stackfood.com/payment-callback?status={$status}&order_id={$orderId}";

return redirect()->away($deepLink);
// ou pour une page HTML avec meta refresh :
// <meta http-equiv="refresh" content="0;url=Fama://stackfood.com/payment-callback?status=...&order_id=...">
```

#### Exemple JavaScript (redirection côté client)

```javascript
const urlParams = new URLSearchParams(window.location.search);
const orderId = urlParams.get('order_id'); // Le backend doit fournir order_id dans l'URL
const status = urlParams.get('status') || 'success';

if (orderId) {
  window.location.href = `Fama://stackfood.com/payment-callback?status=${status}&order_id=${orderId}`;
}
```

### Important

1. **order_id** : Le backend doit inclure l'ID de commande dans l'URL. Si la page reçoit uniquement `payment_id`, il faut faire une requête pour récupérer l'`order_id` associé avant de rediriger.

2. **URL de callback Wave** : Lors de la création du paiement Wave, le backend doit configurer l'URL de succès/échec pour qu'elle contienne les paramètres nécessaires, ou la page payment-success doit pouvoir résoudre `order_id` à partir de `payment_id`.

### Flux complet

1. Utilisateur paie dans l'app Wave
2. Wave appelle l'URL callback du backend (ex. `/payment-success?status=success&payment_id=xxx`)
3. Le backend traite le paiement, récupère l'`order_id`
4. Le backend redirige vers `Fama://stackfood.com/payment-callback?status=success&order_id=123`
5. Android/iOS ouvre l'app Fama avec cette URL
6. L'app affiche l'écran de succès de commande

---

*Documentation pour l'intégration du callback paiement Wave avec l'app Fama*
