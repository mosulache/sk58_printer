# SK58 Printer - Plan de Dezvoltare Continuă

## Status Curent ✅

Versiunea **0.1.0** este completă și publicată pe GitHub!

### Ce avem implementat:
- [x] Structură proiect și configurare
- [x] Driver layer (constants, permissions, scanner, connection)
- [x] API layer (printer, text_style, esc_pos_commands)
- [x] Export principal `sk58_printer.dart`
- [x] Aplicație demo în `example/`
- [x] 20 teste unitare
- [x] Documentație README și CHANGELOG
- [x] 0 erori de linting

---

## Faza 5: Funcționalități Avansate

> ⚠️ **IMPORTANT:** Pentru FIECARE funcționalitate nouă:
> 1. Implementează în `lib/`
> 2. Adaugă teste în `test/`
> 3. **Actualizează `example/lib/main.dart`** cu demo funcțional!
> 4. Actualizează README.md cu exemple de cod

### 5.1 Barcode Generator
**Fișier:** `lib/src/utils/barcode_generator.dart`

Implementează comenzi ESC/POS pentru coduri de bare:
- [ ] Code128 (cel mai folosit)
- [ ] EAN13
- [ ] UPC-A
- [ ] Code39
- [ ] **Example app:** Adaugă tab/secțiune pentru printare barcode

```dart
// API dorit:
await printer.printBarcode('123456789012', BarcodeType.code128);
await printer.printBarcode('5901234123457', BarcodeType.ean13);
```

### 5.2 Image Processor
**Fișier:** `lib/src/utils/image_processor.dart`

Procesare imagini pentru printare:
- [ ] Conversie la bitmap monocrom (1-bit)
- [ ] Redimensionare la 384 pixeli lățime (pentru 58mm)
- [ ] Dithering Floyd-Steinberg pentru grayscale
- [ ] Generare comenzi ESC/POS pentru raster image
- [ ] **Example app:** Adaugă buton pentru printare imagine (din assets sau gallery)

```dart
// API dorit:
final imageBytes = await File('logo.png').readAsBytes();
await printer.printImage(imageBytes);
await printer.printImage(imageBytes, width: 200); // redimensionat
```

**Dependență:** pachetul `image: ^4.1.3` (adaugă în pubspec.yaml!)

### 5.3 Templates GENERICE pentru Etichete
**Fișier:** `lib/src/api/templates.dart`

> ⚠️ **IMPORTANT:** Librăria oferă doar template-uri GENERICE!
> Template-urile specifice domeniului (șuruburi, produse alimentare, etc.) 
> sunt responsabilitatea APLICAȚIEI care folosește librăria!

Șabloane generice predefinite:
- [ ] `Sk58Label` - etichetă de bază (titlu, subtitlu opțional, QR/barcode opțional)
- [ ] `Sk58TwoColumnLabel` - etichetă cu 2 coloane (cheie-valoare)
- [ ] **Example app:** Demo cu template-uri generice

```dart
// API dorit - GENERIC:
await printer.printTemplate(
  Sk58Label(
    title: 'TORX 4x50',
    subtitle: 'Cap T20 - Inox A2',
    qrData: 'SKU-12345',  // opțional
  ),
);

// Sau cu 2 coloane:
await printer.printTemplate(
  Sk58TwoColumnLabel(
    title: 'Product Info',
    rows: [
      ('Type', 'TORX'),
      ('Size', '4x50mm'),
      ('Head', 'T20'),
    ],
  ),
);
```

**NOTĂ:** Aplicația "Screw Label Printer" va defini propriul `ScrewLabel` 
care folosește aceste template-uri generice sau direct API-ul printer-ului.

---

## Faza 6: Îmbunătățiri API

### 6.1 Print Builder Pattern
**Fișier:** `lib/src/api/print_builder.dart`

Builder fluent pentru printări complexe:
- [ ] Implementare builder
- [ ] **Example app:** Demo cu builder pattern (creează o etichetă complexă pas cu pas)

```dart
await printer.build()
  .text('HEADER', style: Sk58TextStyle.boldLarge, align: Sk58Align.center)
  .line()
  .text('Item 1')
  .text('Item 2')
  .qrCode('https://example.com')
  .feed(3)
  .execute();
```

### 6.2 Receipt Template
**Fișier:** `lib/src/api/receipt.dart`

Template pentru bonuri/chitanțe:
- [ ] Header cu logo
- [ ] Linii de produse cu preț
- [ ] Total și subtotal
- [ ] Footer
- [ ] **Example app:** Demo receipt cu produse mock

---

## Faza 7: Testing și Polish

### 7.1 Teste Unitare Suplimentare
- [ ] Teste pentru barcode generator
- [ ] Teste pentru image processor
- [ ] Teste pentru templates

### 7.2 Mock pentru Bluetooth
**Fișier:** `lib/src/driver/mock_connection.dart`

Simulator pentru testare fără printer fizic:
```dart
final printer = Sk58Printer.mock(); // folosește mock connection
await printer.printText('Test'); // nu trimite nimic, doar loghează
```

### 7.3 Integration Tests
- [ ] Test pe Android real cu printer fizic
- [ ] Test pe Linux cu printer fizic

---

## Faza 8: Publicare pub.dev (Opțional)

### 8.1 Pregătire pentru pub.dev
- [ ] Verificare scor `pana` (dart pub publish --dry-run)
- [ ] Adăugare LICENSE
- [ ] Screenshots în README
- [ ] Exemple complete

### 8.2 Publicare
```bash
dart pub publish
```

---

## Priorități Recomandate

1. **ÎNALTĂ** - Barcode Generator (util pentru etichete) + example
2. **ÎNALTĂ** - Template-uri generice (Sk58Label, Sk58TwoColumnLabel) + example
3. **MEDIE** - Image Processor (logo-uri, icoane) + example
4. **MEDIE** - Print Builder Pattern + example
5. **SCĂZUTĂ** - Receipt template (generic) + example
6. **SCĂZUTĂ** - Mock connection

---

## Separarea Responsabilităților

```
┌─────────────────────────────────────────────────────────────┐
│  APLICAȚIE (ex: Screw Label Printer)                        │
│  - UI pentru selectare șuruburi                             │
│  - ScrewLabel, BoltLabel, NutLabel (template-uri specifice) │
│  - Logică de business                                       │
└─────────────────────────┬───────────────────────────────────┘
                          │ folosește
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  LIBRĂRIE (sk58_printer)                                    │
│  - Conexiune Bluetooth                                      │
│  - Comenzi ESC/POS                                          │
│  - printText(), printQR(), printBarcode(), printImage()     │
│  - Template-uri GENERICE (Sk58Label, Sk58TwoColumnLabel)    │
└─────────────────────────────────────────────────────────────┘
```

---

## Structura Example App Recomandată

Transformă example-ul într-o aplicație cu **tab-uri/drawer** pentru fiecare funcționalitate:

```
example/lib/
├── main.dart              # App cu navigare
├── screens/
│   ├── basic_print.dart   # Text + QR (deja implementat)
│   ├── barcode_demo.dart  # Demo barcode-uri
│   ├── image_demo.dart    # Demo printare imagini
│   ├── labels_demo.dart   # Demo templates (ScrewLabel, ProductLabel)
│   └── receipt_demo.dart  # Demo bon fiscal
└── widgets/
    └── printer_status.dart # Widget reutilizabil pentru status conexiune
```

Așa demonstrezi TOATE funcționalitățile într-un singur loc și lumea vede instant ce poate face librăria!

---

## Constrangeri CRITICE (NU UITA!)

1. ⚠️ **NU MODIFICA** UUID-urile din `constants.dart`
2. ⚠️ **NU MODIFICA** chunk size (20 bytes) și delay (100ms)
3. ⚠️ Testează pe device real înainte de orice modificare la driver

---

## Referințe Utile

- [ESC/POS Command Reference](https://reference.epson-biz.com/modules/ref_escpos/index.php)
- [Barcode ESC/POS Commands](https://www.epson-biz.com/modules/ref_escpos/index.php?content_id=128)
- [Image printing (raster bit image)](https://www.epson-biz.com/modules/ref_escpos/index.php?content_id=94)
- [Flutter image package](https://pub.dev/packages/image)
