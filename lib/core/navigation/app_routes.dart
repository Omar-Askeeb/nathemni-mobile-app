import 'package:flutter/material.dart';
import '../../features/home/home_screen.dart';
import '../../features/tasks/presentation/tasks_screen.dart';
import '../../features/tasks/presentation/add_task_screen.dart';
import '../../features/about/about_screen.dart';
import '../../features/barcode/barcode_scanner_screen.dart';
import '../../features/phone_cards/presentation/phone_cards_screen.dart';
import '../../features/bank_accounts/presentation/bank_accounts_screen.dart';
import '../../features/expenses/presentation/expenses_screen.dart';
import '../../features/people/presentation/people_screen.dart';
import '../../features/commitments/presentation/commitments_screen.dart';
import '../../features/meals/presentation/meals_screen.dart';
import '../../features/car_management/presentation/car_dashboard_screen.dart';
import '../../features/tools/presentation/tools_screen.dart';
import '../../features/income/presentation/income_screen.dart';
import '../widgets/placeholder_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String tasks = '/tasks';
  static const String addTask = '/add-task';
  static const String meals = '/meals';
  static const String expenses = '/expenses';
  static const String commitments = '/commitments';
  static const String bankAccounts = '/bank-accounts';
  static const String projects = '/projects';
  static const String phoneCards = '/phone-cards';
  static const String vehicles = '/vehicles';
  static const String equipment = '/equipment';
  static const String people = '/people';
  static const String profile = '/profile';
  static const String barcode = '/barcode';
  static const String notifications = '/notifications';
  static const String syncMode = '/sync-mode';
  static const String support = '/support';
  static const String account = '/account';
  static const String about = '/about';
  static const String income = '/income';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      home: (context) => const HomeScreen(),
      tasks: (context) => const TasksScreen(),
      addTask: (context) => const AddTaskScreen(),

      // Placeholder screens for modules under development
      meals: (context) => const MealsScreen(),
      expenses: (context) => const ExpensesScreen(),
      commitments: (context) => const CommitmentsScreen(),
      bankAccounts: (context) => const BankAccountsScreen(),
      projects: (context) => const PlaceholderScreen(
            title: 'إدارة المشاريع',
            icon: Icons.business_center,
            color: Colors.indigo,
          ),
      phoneCards: (context) => const PhoneCardsScreen(),
      vehicles: (context) => const CarDashboardScreen(),
      equipment: (context) => const ToolsScreen(),
      people: (context) => const PeopleScreen(),
      profile: (context) => const PlaceholderScreen(
            title: 'البيانات الشخصية',
            icon: Icons.person,
            color: Colors.blueGrey,
          ),
      barcode: (context) => const BarcodeScannerScreen(),
      notifications: (context) => const PlaceholderScreen(
            title: 'الإشعارات والسجلات',
            icon: Icons.notifications,
            color: Colors.amber,
          ),
      syncMode: (context) => const PlaceholderScreen(
            title: 'الأوضاع (Offline / Online)',
            icon: Icons.cloud_sync,
            color: Colors.lightBlue,
          ),
      support: (context) => const PlaceholderScreen(
            title: 'الدعم الفني',
            icon: Icons.support_agent,
            color: Colors.green,
          ),
      account: (context) => const PlaceholderScreen(
            title: 'إدارة حساب المستخدم',
            icon: Icons.account_circle,
            color: Colors.blue,
          ),
      about: (context) => const AboutScreen(),
      income: (context) => const IncomeScreen(),
    };
  }
}
