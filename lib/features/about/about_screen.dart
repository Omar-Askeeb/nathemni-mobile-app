import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/navigation/app_drawer.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عن التطبيق'),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Logo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
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
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 120,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'نظّمني',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'رتّب حياتك… بكل بساطة',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'الإصدار 1.0.0',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                  ),
                ],
              ),
            ),

            // Main Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // About App
                  _buildSectionTitle(context, 'عن التطبيق'),
                  const SizedBox(height: 12),
                  _buildTextCard(
                    context,
                    'نظّمني هو تطبيق ذكي لإدارة وتنظيم حياتك اليومية، صُمّم ليساعدك على السيطرة على وقتك، مهامك، ومصاريفك في مكان واحد وبأسلوب سهل يناسب الجميع، سواء كنت طالب، موظف، أو صاحب عمل.',
                  ),
                  const SizedBox(height: 8),
                  _buildTextCard(
                    context,
                    'التطبيق يركز على البساطة والوضوح، ويدعم اللغتين العربية والإنجليزية، مع تجربة استخدام عصرية تناسب الهاتف المحمول وتراعي احتياجات المستخدم اليومية.',
                  ),
                  const SizedBox(height: 24),

                  // Features
                  _buildSectionTitle(context, 'ماذا يقدّم نظّمني؟'),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    context,
                    icon: Icons.task_alt,
                    title: 'إدارة المهام',
                    description: 'إنشاء وتنظيم المهام اليومية مع تنبيهات ذكية',
                    color: Colors.blue,
                  ),
                  _buildFeatureItem(
                    context,
                    icon: Icons.payments,
                    title: 'متابعة المصاريف',
                    description: 'تسجيل المصاريف وتصنيفها لمعرفة أين يذهب مالك',
                    color: Colors.green,
                  ),
                  _buildFeatureItem(
                    context,
                    icon: Icons.schedule,
                    title: 'تنظيم الوقت',
                    description: 'رؤية واضحة ليومك وأولوياتك',
                    color: Colors.orange,
                  ),
                  _buildFeatureItem(
                    context,
                    icon: Icons.security,
                    title: 'خصوصية وأمان',
                    description: 'بياناتك محفوظة بأعلى معايير الأمان',
                    color: Colors.red,
                  ),
                  const SizedBox(height: 24),

                  // Why Nathemni
                  _buildSectionTitle(context, 'لماذا نظّمني؟'),
                  const SizedBox(height: 12),
                  _buildTextCard(
                    context,
                    'لأن الفوضى تضيّع الوقت والطاقة، ونظّمني جاء ليكون مساعدك الشخصي في التنظيم، بدون تعقيد، وبدون أدوات كثيرة متفرقة. تطبيق واحد… لكل شيء مهم في يومك.',
                  ),
                  const SizedBox(height: 24),

                  // Developer Info
                  _buildSectionTitle(context, 'المطوّر'),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.code,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SkepTeck',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'مطور نظم وتطبيقات',
                                      style:
                                          Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'مهندس تقنية معلومات، متخصص في تصميم وبناء حلول رقمية عملية تخدم الأفراد والشركات:',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          _buildBulletPoint('تطبيقات الهواتف الذكية'),
                          _buildBulletPoint('أنظمة الويب'),
                          _buildBulletPoint('حلول إدارة الأعمال'),
                          _buildBulletPoint('الأنظمة المخصصة حسب احتياج العميل'),
                          _buildBulletPoint('الشبكات والبنية التحتية'),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => _launchURL('https://askeeb.ly'),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.language,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'https://askeeb.ly',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.open_in_new,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Vision
                  _buildSectionTitle(context, 'رؤيتنا'),
                  const SizedBox(height: 12),
                  _buildTextCard(
                    context,
                    'نسعى لتقديم حلول رقمية ذكية تساعد المستخدم العربي على تنظيم حياته وأعماله بسهولة، وبأدوات حديثة تضاهي أفضل التطبيقات العالمية.',
                  ),
                  const SizedBox(height: 24),

                  // Contact Section
                  _buildSectionTitle(context, 'تواصل معنا'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildContactCard(
                          context,
                          icon: Icons.web,
                          label: 'الموقع',
                          value: 'askeeb.ly',
                          onTap: () => _launchURL('https://askeeb.ly'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildContactCard(
                          context,
                          icon: Icons.email,
                          label: 'البريد',
                          value: 'info@askeeb.ly',
                          onTap: () =>
                              _launchURL('mailto:info@askeeb.ly'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Footer
                  Center(
                    child: Column(
                      children: [
                        Text(
                          '© 2026 نظّمني - جميع الحقوق محفوظة',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Developed by SkepTeck',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }

  Widget _buildTextCard(BuildContext context, String text) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.8,
              ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
