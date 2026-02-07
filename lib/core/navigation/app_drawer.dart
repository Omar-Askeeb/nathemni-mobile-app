import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 50,
                    height: 50,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'نظمني',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'تطبيقك الشخصي للتنظيم',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                ),
              ],
            ),
          ),

          // الرئيسية
          _buildDrawerItem(
            context,
            icon: Icons.home,
            title: 'الرئيسية',
            route: '/',
          ),

          const Divider(),

          // المهام والتنظيم اليومي
          _buildDrawerItem(
            context,
            icon: Icons.task_alt,
            title: 'المهام والتنظيم اليومي',
            route: '/tasks',
          ),

          const Divider(),

          // إدارة الوجبات
          _buildDrawerItem(
            context,
            icon: Icons.restaurant_menu,
            title: 'إدارة الوجبات',
            route: '/meals',
          ),

          const Divider(),

          // القسم المالي
          _buildSectionHeader(context, 'الإدارة المالية'),
          _buildDrawerItem(
            context,
            icon: Icons.payments,
            title: 'تتبع المصاريف',
            route: '/expenses',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.account_balance_wallet,
            title: 'الالتزامات والديون',
            route: '/commitments',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.account_balance,
            title: 'إدارة الحسابات المصرفية',
            route: '/bank-accounts',
          ),

          const Divider(),

          // إدارة المشاريع
          _buildDrawerItem(
            context,
            icon: Icons.business_center,
            title: 'إدارة المشاريع',
            route: '/projects',
          ),

          const Divider(),

          // الإدارات الأخرى
          _buildSectionHeader(context, 'إدارات أخرى'),
          _buildDrawerItem(
            context,
            icon: Icons.phone_android,
            title: 'إدارة بطاقات الهاتف',
            route: '/phone-cards',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.directions_car,
            title: 'إدارة السيارات',
            route: '/vehicles',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.build,
            title: 'إدارة المعدات والأدوات',
            route: '/equipment',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.people,
            title: 'إدارة الأشخاص',
            route: '/people',
          ),

          const Divider(),

          // أدوات
          _buildSectionHeader(context, 'أدوات'),
          _buildDrawerItem(
            context,
            icon: Icons.person,
            title: 'البيانات الشخصية',
            route: '/profile',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.qr_code_scanner,
            title: 'الباركود و QR Code',
            route: '/barcode',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.notifications,
            title: 'الإشعارات والسجلات',
            route: '/notifications',
          ),

          const Divider(),

          // الإعدادات
          _buildSectionHeader(context, 'الإعدادات'),
          _buildDrawerItem(
            context,
            icon: Icons.cloud_sync,
            title: 'الأوضاع (Offline / Online)',
            route: '/sync-mode',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.support_agent,
            title: 'الدعم الفني',
            route: '/support',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.account_circle,
            title: 'إدارة حساب المستخدم',
            route: '/account',
          ),
          _buildDrawerItem(
            context,
            icon: Icons.info,
            title: 'عن التطبيق',
            route: '/about',
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {
        Navigator.pop(context); // Close drawer
        Navigator.pushNamed(context, route);
      },
    );
  }
}
