// lib/screens/handbook_screen.dart
// ==================================
// Security Handbook - Educational content about spam, phishing, and data protection
// This is a CORE FEATURE of Sifitlier

import 'package:flutter/material.dart';

class HandbookScreen extends StatefulWidget {
  const HandbookScreen({super.key});

  @override
  State<HandbookScreen> createState() => _HandbookScreenState();
}

class _HandbookScreenState extends State<HandbookScreen> {
  final List<HandbookChapter> _chapters = [
    HandbookChapter(
      id: 1,
      title: 'Understanding Spam',
      icon: Icons.email,
      color: Colors.red,
      description: 'Learn what spam is and how to identify it',
      sections: [
        HandbookSection(
          title: 'What is Spam?',
          content: '''
Spam refers to unsolicited, unwanted messages sent in bulk, typically for advertising, phishing, or spreading malware. These messages can arrive through:

• Email - Unwanted promotional emails or scam messages
• SMS - Text messages from unknown numbers with suspicious links
• Messaging Apps - Spam in WhatsApp, Telegram, and other platforms

Spam wastes your time, clutters your inbox, and can pose serious security risks if you interact with malicious content.
''',
        ),
        HandbookSection(
          title: 'Common Spam Indicators',
          content: '''
Watch for these red flags that often indicate spam:

🚩 Urgency Language
"Act NOW!", "Limited time!", "Immediate action required!"

🚩 Too Good to Be True
"You've won \$1,000,000!", "Free iPhone!", "Congratulations!"

🚩 Suspicious Sender
Unknown numbers, misspelled company names, random email addresses

🚩 Grammar & Spelling Errors
Professional companies don't send messages with obvious mistakes

🚩 Suspicious Links
Shortened URLs, misspelled domains (amaz0n.com vs amazon.com)

🚩 Requests for Personal Information
Legitimate companies won't ask for passwords or credit cards via SMS/email
''',
        ),
        HandbookSection(
          title: 'How Sifitlier Detects Spam',
          content: '''
Sifitlier uses AI-powered spam detection to protect you:

1. Machine Learning Analysis
   Our model is trained on thousands of spam messages to recognize patterns

2. Keyword Detection
   Identifies common spam phrases and suspicious language

3. Risk Level Assessment
   Assigns LOW, MEDIUM, or HIGH risk levels based on multiple factors

4. Real-time Alerts
   Notifies you immediately when suspicious messages are detected

The more you use Sifitlier, the better it becomes at protecting you!
''',
        ),
      ],
    ),
    HandbookChapter(
      id: 2,
      title: 'Recognizing Phishing',
      icon: Icons.phishing,
      color: Colors.orange,
      description: 'Protect yourself from phishing attacks',
      sections: [
        HandbookSection(
          title: 'What is Phishing?',
          content: '''
Phishing is a type of cyber attack where criminals try to steal your sensitive information by pretending to be a trusted entity.

How Phishing Works:
1. Attacker sends a message pretending to be a bank, company, or government
2. Message contains urgency to make you act without thinking
3. You're directed to a fake website that looks legitimate
4. You enter your credentials, which are stolen

Common Phishing Targets:
• Banking credentials
• Email passwords
• Social media accounts
• Credit card information
• Personal identification numbers
''',
        ),
        HandbookSection(
          title: 'Types of Phishing Attacks',
          content: '''
Email Phishing
Mass emails impersonating banks or services
"Your account has been suspended. Click here to verify."

Smishing (SMS Phishing)
Text messages with malicious links
"Your package couldn't be delivered. Track here: bit.ly/xxx"

Vishing (Voice Phishing)
Phone calls from fake customer service
"This is your bank. We detected fraud on your account."

Spear Phishing
Targeted attacks using personal information
"Hi [Your Name], please review the attached invoice."

Clone Phishing
Copies of legitimate emails with malicious links
Replicated company newsletters with altered links
''',
        ),
        HandbookSection(
          title: 'How to Verify Legitimacy',
          content: '''
Before clicking any link or providing information:

✅ Check the Sender
Verify email addresses and phone numbers match official contacts

✅ Look at the URL
Hover over links to see the actual destination
Check for HTTPS and correct spelling

✅ Contact Directly
Call the company using their official number (not the one in the message)

✅ Don't Rush
Legitimate companies give you time to respond
Urgency is a manipulation tactic

✅ Check for Personalization
Real companies usually address you by name
"Dear Customer" is often a red flag

✅ Trust Your Instincts
If something feels wrong, it probably is
''',
        ),
      ],
    ),
    HandbookChapter(
      id: 3,
      title: 'Protecting Your Data',
      icon: Icons.lock,
      color: Colors.blue,
      description: 'Keep your sensitive information safe',
      sections: [
        HandbookSection(
          title: 'Types of Sensitive Data',
          content: '''
Sifitlier's DLP feature protects various types of sensitive data:

💳 Financial Information
• Credit/Debit card numbers
• Bank account numbers
• IBAN codes
• CVV/Security codes

🆔 Identity Documents
• Social Security Numbers (SSN)
• National ID (NRIC/IC)
• Passport numbers
• Driver's license numbers

🔐 Authentication Data
• Passwords
• PIN codes
• API keys
• Access tokens

📱 Personal Information
• Phone numbers
• Email addresses
• Home addresses
• Dates of birth
''',
        ),
        HandbookSection(
          title: 'Why DLP Matters',
          content: '''
Data Loss Prevention (DLP) helps you avoid accidentally sharing sensitive information.

Real-World Scenarios:

❌ Scenario 1: You text your credit card number to "verify" a purchase - but it's a scammer

❌ Scenario 2: You email a password to a colleague, but CC the wrong person

❌ Scenario 3: You share your NRIC number thinking it's a legitimate request

Consequences of Data Leaks:
• Identity theft
• Financial fraud
• Account takeovers
• Privacy violations
• Legal issues

Sifitlier DLP protects you by:
• Scanning outgoing messages before you send
• Alerting you when sensitive data is detected
• Showing exactly what data was found
• Giving you the choice to proceed or edit
''',
        ),
        HandbookSection(
          title: 'Safe Data Sharing Practices',
          content: '''
DO:
✅ Use encrypted channels for sensitive data
✅ Verify the recipient before sharing
✅ Use secure file sharing services
✅ Delete sensitive messages after they're received
✅ Use password managers instead of sharing passwords

DON'T:
❌ Send credit card numbers via SMS or email
❌ Share passwords in plain text
❌ Post personal documents on social media
❌ Store sensitive data in notes apps
❌ Share OTPs with anyone (even "bank employees")

Better Alternatives:
• Use in-app payment systems instead of sharing card details
• Use temporary secure links for document sharing
• Set up family sharing instead of sharing passwords
• Use biometric authentication when available
''',
        ),
      ],
    ),
    HandbookChapter(
      id: 4,
      title: 'Safe Messaging Practices',
      icon: Icons.chat,
      color: Colors.green,
      description: 'Best practices for secure communication',
      sections: [
        HandbookSection(
          title: 'Securing Your Accounts',
          content: '''
Enable Two-Factor Authentication (2FA)
Add an extra layer of security beyond your password

Use Strong Passwords
• Minimum 12 characters
• Mix of letters, numbers, and symbols
• Different password for each account
• Use a password manager

Review App Permissions
• Regularly check what apps can access
• Revoke unnecessary permissions
• Be cautious with new apps

Keep Software Updated
• Install security updates promptly
• Enable automatic updates
• Update messaging apps regularly

Use Official Apps Only
• Download from official app stores
• Avoid APK files from unknown sources
• Check app reviews and ratings
''',
        ),
        HandbookSection(
          title: 'Recognizing Social Engineering',
          content: '''
Social engineering is manipulating people into giving up confidential information.

Common Tactics:

🎭 Pretexting
Creating a fake scenario to gain trust
"I'm from IT, I need your password to fix your email"

😨 Fear/Urgency
Creating panic to force quick decisions
"Your account will be deleted in 24 hours!"

🎁 Baiting
Offering something tempting
"Free gift card if you complete this survey"

🤝 Quid Pro Quo
Offering a service in exchange for information
"I'll help fix your computer if you give me remote access"

How to Respond:
• Take your time - don't let anyone rush you
• Verify through official channels
• When in doubt, say no
• Report suspicious contacts
''',
        ),
        HandbookSection(
          title: 'What To Do If Compromised',
          content: '''
If you've fallen victim to a scam or data breach:

Immediate Actions:

1️⃣ Change Passwords
Start with your email and financial accounts

2️⃣ Contact Your Bank
Report any suspicious transactions
Consider freezing your cards

3️⃣ Enable Fraud Alerts
Contact credit bureaus to flag your accounts

4️⃣ Document Everything
Save messages, emails, and transaction records

5️⃣ Report the Incident
• Local police
• Cybercrime reporting centers
• The platform where the scam occurred

Long-term Actions:
• Monitor your credit reports
• Review account statements regularly
• Consider identity theft protection services
• Educate family members about the incident

Remember:
It's not your fault - scammers are professionals.
The most important thing is to act quickly!
''',
        ),
      ],
    ),
    HandbookChapter(
      id: 5,
      title: 'Platform-Specific Tips',
      icon: Icons.devices,
      color: Colors.purple,
      description: 'Security tips for SMS, Email, and Telegram',
      sections: [
        HandbookSection(
          title: 'SMS Security',
          content: '''
Risks Specific to SMS:
• SMS messages are not encrypted
• Sender IDs can be spoofed
• Links in SMS are harder to verify
• SIM swapping attacks

Protection Tips:

✅ Never click links in SMS from unknown numbers
Even if they appear to be from a known company

✅ Don't reply to suspicious messages
This confirms your number is active

✅ Block and report spam numbers
Use your phone's built-in features

✅ Be wary of "verify" requests
Banks rarely send verification links via SMS

✅ Enable spam filtering
Use Sifitlier and your phone's built-in filters

✅ Consider a SIM PIN
Protects against unauthorized SIM usage
''',
        ),
        HandbookSection(
          title: 'Email Security',
          content: '''
Email Threats:
• Phishing emails
• Malware attachments
• Business Email Compromise (BEC)
• Account takeover

Protection Tips:

✅ Check sender addresses carefully
support@amaz0n.com vs support@amazon.com

✅ Don't download unexpected attachments
Even from known contacts (they might be compromised)

✅ Use email filtering
Enable spam filters and phishing protection

✅ Verify unusual requests
"Boss" asking for gift cards? Call to confirm.

✅ Look before you click
Hover over links to see actual URLs

✅ Use separate emails
One for personal, one for financial, one for subscriptions
''',
        ),
        HandbookSection(
          title: 'Telegram Security',
          content: '''
Telegram-Specific Risks:
• Fake groups impersonating legitimate ones
• Bot scams
• "Investment" scheme promotions
• Crypto giveaway scams

Protection Tips:

✅ Verify group authenticity
Check official websites for real group links

✅ Be cautious with bots
Don't give bots unnecessary permissions

✅ Enable Two-Step Verification
Settings → Privacy and Security → Two-Step Verification

✅ Hide your phone number
Settings → Privacy → Phone Number → Nobody

✅ Block and report spam
Use the report feature for suspicious accounts

✅ Don't join "guaranteed profit" groups
If it sounds too good to be true, it is

✅ Verify admins in official groups
Real admins won't DM you first asking for money
''',
        ),
      ],
    ),
  ];

  int _selectedChapterIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Handbook'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearch(context),
          ),
        ],
      ),
      body: Row(
        children: [
          // Chapter Navigation (for tablets/landscape)
          if (MediaQuery.of(context).size.width > 600)
            SizedBox(
              width: 250,
              child: _buildChapterList(),
            ),

          // Main Content
          Expanded(
            child: _buildChapterContent(),
          ),
        ],
      ),
      // Bottom navigation for phones
      bottomNavigationBar: MediaQuery.of(context).size.width <= 600
          ? _buildBottomNavigation()
          : null,
    );
  }

  Widget _buildChapterList() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      child: ListView.builder(
        itemCount: _chapters.length,
        itemBuilder: (context, index) {
          final chapter = _chapters[index];
          final isSelected = index == _selectedChapterIndex;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  isSelected ? chapter.color : chapter.color.withOpacity(0.2),
              child: Icon(
                chapter.icon,
                color: isSelected ? Colors.white : chapter.color,
                size: 20,
              ),
            ),
            title: Text(
              chapter.title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            onTap: () => setState(() => _selectedChapterIndex = index),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: _selectedChapterIndex,
      onTap: (index) => setState(() => _selectedChapterIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: _chapters[_selectedChapterIndex].color,
      items: _chapters
          .map((chapter) => BottomNavigationBarItem(
                icon: Icon(chapter.icon),
                label: chapter.title.split(' ').first, // Short label
              ))
          .toList(),
    );
  }

  Widget _buildChapterContent() {
    final chapter = _chapters[_selectedChapterIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chapter Header
          Card(
            color: chapter.color,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(chapter.icon, color: Colors.white, size: 48),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chapter ${chapter.id}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          chapter.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          chapter.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Sections
          ...chapter.sections
              .map((section) => _buildSection(section, chapter.color)),
        ],
      ),
    );
  }

  Widget _buildSection(HandbookSection section, Color accentColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(Icons.article, color: accentColor),
        title: Text(
          section.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildFormattedContent(section.content),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedContent(String content) {
    // Simple markdown-like formatting
    final lines = content.trim().split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
      } else if (line.startsWith('• ') || line.startsWith('- ')) {
        // Bullet point
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(child: Text(line.substring(2))),
            ],
          ),
        ));
      } else if (RegExp(r'^[0-9]️⃣|^[0-9]\.|^[✅❌🚩💳🆔🔐📱🎭😨🎁🤝]')
          .hasMatch(line.trim())) {
        // Emoji-started lines or numbered lines
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(line, style: const TextStyle(fontSize: 15)),
        ));
      } else if (line.trim().endsWith(':') && line.trim().length < 50) {
        // Section headers (lines ending with colon)
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(
            line.trim(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ));
      } else {
        // Regular text
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(line, style: const TextStyle(height: 1.5)),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  void _showSearch(BuildContext context) {
    showSearch(
      context: context,
      delegate: HandbookSearchDelegate(_chapters),
    );
  }
}

// Data Models
class HandbookChapter {
  final int id;
  final String title;
  final IconData icon;
  final Color color;
  final String description;
  final List<HandbookSection> sections;

  HandbookChapter({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    required this.sections,
  });
}

class HandbookSection {
  final String title;
  final String content;

  HandbookSection({
    required this.title,
    required this.content,
  });
}

// Search Delegate
class HandbookSearchDelegate extends SearchDelegate<String> {
  final List<HandbookChapter> chapters;

  HandbookSearchDelegate(this.chapters);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    if (query.isEmpty) {
      return const Center(
        child: Text('Enter a search term'),
      );
    }

    final results = <Map<String, dynamic>>[];

    for (final chapter in chapters) {
      for (final section in chapter.sections) {
        if (section.title.toLowerCase().contains(query.toLowerCase()) ||
            section.content.toLowerCase().contains(query.toLowerCase())) {
          results.add({
            'chapter': chapter,
            'section': section,
          });
        }
      }
    }

    if (results.isEmpty) {
      return const Center(
        child: Text('No results found'),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        final chapter = result['chapter'] as HandbookChapter;
        final section = result['section'] as HandbookSection;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: chapter.color.withOpacity(0.2),
            child: Icon(chapter.icon, color: chapter.color),
          ),
          title: Text(section.title),
          subtitle: Text(chapter.title),
          onTap: () => close(context, ''),
        );
      },
    );
  }
}
