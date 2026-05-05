<h1 align="center">
  <br/>
  💸 SpendSnap
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

## ✨ Features

### 🤖 AI & Automation
* **Smart NLP Entry**: Type *"Spent ₹500 on dinner"* and Gemini instantly categorizes and logs structured data.
* **Receipt Vision Scanner**: Snap a photo or upload an image. The AI extracts the amount, vendor, and dynamically applies categories.
* **Bank Sync Simulation**: Auto-categories mocked HTTP network fetches to simulate sandbox open-banking feeds.

### 💎 Core Financials
* **Transactions**: Add, edit, swipe-to-delete, recurring billing, transaction notes, and filter incomes and expenses.
* **Budgets**: Prevent overspending with real-time, progress-animated category limits.
* **Goals**: Establish specific time-bound saving targets. Add incremental funds.
* **Insights**: Beautiful interactive Pie charts and 6-month Line trend graphs.
* **Custom UI**: Fluid animations using `flutter_animate`, floating pill-shaped dock, completely custom-built theme, and custom launcher logo.

### 🧠 Intelligence Engines
* **Spending Health Score (0-100)**: Assesses 4 dimensions—Budget Adherence, Savings Rate, Spending Trend, and Category Diversity—to grade your fiscal responsibility. 
* **Smart Budget Recommendations**: Implements the traditional **50/30/20 rule** dynamically blended against your actual 3-month personal baseline for hyper-realistic budget targets.
* **Stateful Notifications**: Alert center tracking unread alerts for budget overflows and goal completions.

---

## 🏗️ Architecture

SpendSnap is built using **Feature-First / Clean Architecture**. It strictly enforces the **BLoC** pattern for state management separating UI entirely from the Firebase Database layers.

```text
lib/
├── core/
│   ├── theme/          # AppColors, AppTypography
│   ├── utils/          # CurrencyFormatter, Validators
│   └── widgets/        # Reusable UI (SnapCard, SnapTextField, GlowButton)
├── data/
│   ├── models/         # Data Models (TransactionModel, BudgetModel, etc.)
│   └── repositories/   # Firebase abstract access
├── logic/
│   ├── blocs/          # AuthBloc, TransactionBloc, BudgetBloc, GoalBloc
│   └── services/       # AiTransactionService, HealthScoreService
└── ui/                 
    └── screens/        # Views mapped to GoRouter
```

---

## 🚀 Getting Started

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

## 🧪 Testing

SpendSnap ships with rigorous coverage for all algorithm-heavy functionality to prevent mathematical regressions.

```bash
flutter test
```
*Includes comprehensive Unit Tests for the Health Score algorithms, Recommendation engine blending rules, and UI Widget Tests.*
