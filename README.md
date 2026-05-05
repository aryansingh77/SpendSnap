<h1 align="center">
  <br/>
   SpendSnap
</h1>

<h4 align="center">An intelligent, beautifully designed personal finance manager powered by Flutter, Firebase, and Google Gemini AI.</h4>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white" />
  <img alt="Dart" src="https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white" />
  <img alt="Firebase" src="https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase" />
  <img alt="Gemini" src="https://img.shields.io/badge/Google%20Gemini-8E75B2?style=for-the-badge&logo=google&logoColor=white" />
  <img alt="BLoC" src="https://img.shields.io/badge/Architecture-BLoC-blue?style=for-the-badge" />
</p>

---

##  Features

###  AI & Automation
* **Smart NLP Entry**: Type *"Spent ₹500 on dinner"* and Gemini instantly categorizes and logs structured data.
* **Receipt Vision Scanner**: Snap a photo or upload an image. The AI extracts the amount, vendor, and dynamically applies categories.
* **Bank Sync Simulation**: Auto-categories mocked HTTP network fetches to simulate sandbox open-banking feeds.

###  Core Financials
* **Transactions**: Add, edit, swipe-to-delete, recurring billing, transaction notes, and filter incomes and expenses.
* **Budgets**: Prevent overspending with real-time, progress-animated category limits.
* **Goals**: Establish specific time-bound saving targets. Add incremental funds.
* **Insights**: Beautiful interactive Pie charts and 6-month Line trend graphs.
* **Custom UI**: Fluid animations using `flutter_animate`, floating pill-shaped dock, completely custom-built theme, and custom launcher logo.

###  Intelligence Engines
* **Spending Health Score (0-100)**: Assesses 4 dimensions—Budget Adherence, Savings Rate, Spending Trend, and Category Diversity—to grade your fiscal responsibility. 
* **Smart Budget Recommendations**: Implements the traditional **50/30/20 rule** dynamically blended against your actual 3-month personal baseline for hyper-realistic budget targets.
* **Stateful Notifications**: Alert center tracking unread alerts for budget overflows and goal completions.

---

##  Architecture & Technical Design

SpendSnap is built using **Feature-First Clean Architecture**. It strictly enforces the **BLoC** (Business Logic Component) pattern for state management, rigidly separating the UI layer from the Firebase/API data layers.

### 1. Directory Structure

```text
lib/
├── core/
│   ├── theme/          # AppColors, AppTypography, CustomThemes
│   ├── constants/      # Category lists, hardcoded allocation guides
│   ├── utils/          # CurrencyFormatter, InputValidators
│   └── widgets/        # Reusable UI (SnapCard, SnapTextField, GlowButton, Charts)
├── data/
│   ├── models/         # Strongly-typed models (TransactionModel, BudgetModel)
│   └── repositories/   # Firebase abstraction APIs (Auth, Transactions, CRUD operations)
├── logic/
│   ├── blocs/          # State controllers: AuthBloc, TransactionBloc, BudgetBloc
│   └── services/       # Core engines: AiTransactionService, HealthScoreService
└── ui/                 
    └── screens/        # Presentation views dynamically built via BlocBuilders
```

### 2. State Management (BLoC Pattern)
* **UI Layer**: Presentation files inside `ui/screens` only dispatch explicit *Events* and rebuild strictly via `BlocBuilder` / `BlocConsumer`. They never parse raw Firebase data.
* **Business Logic Layer**: Isolated `logic/blocs` listen for events, run validations, contact repositories, and emit new frozen *States* (e.g., `TransactionLoading -> TransactionLoaded(List<TransactionModel>)`).
* **Data Layer**: Repositories abstract the database. If we move from Firebase to Supabase, the BLoC and UI files require precisely **zero** changes.

### 3. Firebase Data Model (NoSQL Document Scoping)
Data is structured relationally using strong document scopes to prevent cross-account access leakage:

```text
Root > Collection('users') 
  └─ > Document ('{uid}')      <-- Base isolated scope
         │
         ├─> SubCollection('transactions') 
         │      └─ Document ({ category, amount, type, date, title })
         │
         ├─> SubCollection('budgets') 
         │      └─ Document ({ limitAmount, category })
         │
         └─> SubCollection('goals')
                └─ Document ({ targetAmount, currentAmount })
```

### 4. Custom Logic Engines & Services

* **`ai_transaction_service.dart`**: Connects via `google_generative_ai`. Uses `gemini-flash-latest` for zero-shot text-to-JSON mappings, and Multimodal Vision models to parse `Uint8List` image byte receipts natively on device.
* **`spending_health_score_service.dart`**: A 100-point deterministic grading algorithm. Analyzes rolling 30-day budget adherence natively locally without requiring heavy cloud-functions.
* **`budget_recommendation_service.dart`**: Uses the 50/30/20 algorithm, but blends it at a 60/40 ratio with a user's *actual* historical spending averages to prevent shockingly unrealistic goals.

---

##  Getting Started

### Prerequisites
* Flutter SDK (3.x+)
* Firebase Account
* Google AI Studio Account (for Gemini API Key)

### Installation

1. **Clone & Install Dependencies**
```bash
git clone https://github.com/aryansingh77/SpendSnap.git
cd spendsnap
flutter pub get
```

2. **Configure Firebase**
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```
*Ensure you enable **Email/Password Authentication** and **Firestore Database** in your Firebase Console.*

3. **Configure Gemini API**
Head to `lib/logic/services/ai_transaction_service.dart` and paste your free API key:
```dart
static const String _apiKey = 'YOUR_API_KEY_HERE';
```

4. **Run Application**
```bash
flutter run
```

---

##  Testing

SpendSnap ships with rigorous coverage for all algorithm-heavy functionality to prevent mathematical regressions.

```bash
flutter test
```
*Includes comprehensive Unit Tests for the Health Score algorithms, Recommendation engine blending rules, and UI Widget Tests.*
