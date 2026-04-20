# 🚴 Cycling Wallet

> **Όλα τα αγωνιστικά σου έγγραφα — στη μύτη των δακτύλων σου.**

Μια Flutter εφαρμογή για γρήγορη αποθήκευση και επίδειξη αγωνιστικών εγγράφων ποδηλασίας (UCI, ΕΟΠ, κάρτα υγείας) — με ασφαλή, 100% offline πρόσβαση.

---

## 🎯 Για ποιον είναι

| 👤 Αθλητής / Συνοδός | 🔒 Privacy-first χρήστης |
|---|---|
| Άμεση επίδειξη εγγράφων στον έλεγχο αγώνα | Όλα τα έγγραφα στο κινητό, χωρίς cloud |

---

## ✨ Χαρακτηριστικά

- 🪪 **Κάρτες εγγράφων** με 1–2 φωτογραφίες ανά έγγραφο
- 🔍 **Fullscreen προβολή** με zoom & pan
- 📷 **Επιλογή** από κάμερα ή συλλογή
- 💾 **Αυτόματη αποθήκευση** και offline λειτουργία
- ☀️ **Προσωρινή ενίσχυση φωτεινότητας** κατά την προβολή

---

## 🔐 Αποθήκευση & Ιδιωτικότητα

- Οι φωτογραφίες αντιγράφονται σε **ιδιωτικό χώρο** της εφαρμογής (`Application Documents / app_flutter`) και δεν εξαρτώνται από το album.
- Αν διαγραφεί μια φωτογραφία από τη συλλογή, η εφαρμογή **κρατά το δικό της αντίγραφο**.
- ❌ Δεν γίνεται αποστολή δεδομένων σε server ή cloud.

---

## 🛠️ Τεχνικές λεπτομέρειες

| Στοιχείο | Τεχνολογία |
|---|---|
| Framework | Flutter (Android / iOS) |
| Metadata | `shared_preferences` |
| Αρχεία εικόνας | `path_provider` (app-specific directory) |
| Προβολή εικόνας | `photo_view` |
| Επιλογή φωτογραφίας | `image_picker` |

---

## 📁 Δομή Project

```
lib/
├── main.dart
├── models/
│   └── document.dart
├── screens/
│   └── home_screen.dart
├── services/
│   └── storage_service.dart
└── widgets/
    └── document_card.dart
```

---

## 🚀 Εγκατάσταση & Εκτέλεση

```bash
# 1. Εγκατάσταση Flutter SDK
# https://docs.flutter.dev/get-started/install

# 2. Λήψη dependencies
flutter pub get

# 3. Εκτέλεση
flutter run
```

### 📦 Έτοιμα Builds

Για εγκατάσταση σε Android ή iPhone, υπάρχουν έτοιμες εκδόσεις στα **[GitHub Releases](../../releases)** — δεν απαιτείται Flutter SDK.

---

## 📋 Permissions

<details>
<summary><strong>Android</strong></summary>

```xml
CAMERA
READ_EXTERNAL_STORAGE
WRITE_EXTERNAL_STORAGE  <!-- ανάλογα με έκδοση Android -->
```
</details>

<details>
<summary><strong>iOS</strong></summary>

```
NSCameraUsageDescription
NSPhotoLibraryUsageDescription
NSPhotoLibraryAddUsageDescription
```
</details>

---

## 📝 Σημειώσεις

- Τα δεδομένα αποθηκεύονται **τοπικά** και διαγράφονται με απεγκατάσταση.
- Αν αλλάξει φωτογραφία, αντικαθίσταται αυτόματα το αντίγραφο στο app directory.
