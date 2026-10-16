import 'package:lucide_icons/lucide_icons.dart';

/// Static data constants — Nexora.

const Map<String, String> kCategories = {
  'food': 'Food & Dining',
  'groceries': 'Groceries',
  'transport': 'Transport',
  'bills': 'Bills & Utilities',
  'rent': 'Rent & Housing',
  'shopping': 'Shopping',
  'entertainment': 'Entertainment',
  'health': 'Health & Fitness',
  'education': 'Education',
  'other': 'Other',
};

const Map<String, String> kIncomeCategories = {
  'salary': 'Salary',
  'freelance': 'Freelance',
  'investment': 'Investment',
  'gift': 'Gift',
  'refund': 'Refund',
  'other': 'Other',
};

/// Icon mapping for categories
const Map<String, dynamic> kCategoryIcons = {
  'food': LucideIcons.utensils,
  'groceries': LucideIcons.shoppingCart,
  'transport': LucideIcons.car,
  'bills': LucideIcons.zap,
  'rent': LucideIcons.home,
  'shopping': LucideIcons.shoppingBag,
  'entertainment': LucideIcons.gamepad2,
  'health': LucideIcons.heart,
  'education': LucideIcons.graduationCap,
  'salary': LucideIcons.banknote,
  'freelance': LucideIcons.laptop,
  'investment': LucideIcons.trendingUp,
  'gift': LucideIcons.gift,
  'refund': LucideIcons.undo2,
  'other': LucideIcons.moreHorizontal,
};

const List<String> kPriorities = ['low', 'medium', 'high', 'urgent'];

const Map<String, String> kPriorityLabels = {
  'low': 'Low',
  'medium': 'Medium',
  'high': 'High',
  'urgent': 'Urgent',
};

const Map<String, String> kCurrencySymbols = {
  'USD': '\$',
  'EUR': '€',
  'GBP': '£',
  'INR': '₹',
  'PKR': '₨',
  'JPY': '¥',
  'CAD': 'C\$',
  'AUD': 'A\$',
  'AED': 'د.إ',
  'SAR': '﷼',
  'BDT': '৳',
};

enum ResourceType { document, subscription, inventory, contact, password, wifiPassword, bankCard }

const Map<ResourceType, String> kResourceTypeLabels = {
  ResourceType.document: 'Documents',
  ResourceType.subscription: 'Subscriptions',
  ResourceType.inventory: 'Inventory',
  ResourceType.contact: 'Contacts',
  ResourceType.password: 'Passwords',
  ResourceType.wifiPassword: 'WiFi',
  ResourceType.bankCard: 'Cards',
};

const Map<ResourceType, dynamic> kResourceTypeIconData = {
  ResourceType.document: LucideIcons.fileBadge,
  ResourceType.subscription: LucideIcons.repeat,
  ResourceType.inventory: LucideIcons.package,
  ResourceType.contact: LucideIcons.contact,
  ResourceType.password: LucideIcons.keyRound,
  ResourceType.wifiPassword: LucideIcons.wifi,
  ResourceType.bankCard: LucideIcons.creditCard,
};

class NoteTemplate {
  final String key;
  final String title;
  final String body;
  final dynamic icon;
  const NoteTemplate(this.key, this.title, this.body, [this.icon]);
}

const List<NoteTemplate> kNoteTemplates = [
  NoteTemplate(
    'meeting',
    'Meeting Notes',
    '# Meeting Notes\n\n**Date:** \n**Attendees:** \n\n## Agenda\n1. \n\n## Notes\n\n## Action Items\n- [ ] ',
    LucideIcons.users,
  ),
  NoteTemplate(
    'journal',
    'Journal Entry',
    '## How am I feeling today?\n\n## What went well?\n\n## What could be better?\n',
    LucideIcons.heart,
  ),
  NoteTemplate(
    'recipe',
    'Recipe',
    '## Ingredients\n- \n\n## Instructions\n1. \n\n## Notes\n',
    LucideIcons.chefHat,
  ),
  NoteTemplate(
    'checklist',
    'Checklist',
    '## Checklist\n\n- [ ] Item 1\n- [ ] Item 2\n- [ ] Item 3\n- [ ] Item 4\n- [ ] Item 5\n',
    LucideIcons.listChecks,
  ),
  NoteTemplate(
    'brainstorm',
    'Brainstorm',
    '# 💡 Brainstorm Session\n\n## Topic\n\n## Ideas\n1. \n2. \n3. \n\n## Next Steps\n',
    LucideIcons.lightbulb,
  ),
];

class NoteFolder {
  final String id;
  final String name;
  const NoteFolder(this.id, this.name);
}

const List<NoteFolder> kDefaultFolders = [
  NoteFolder('inbox', 'Inbox'),
  NoteFolder('work', 'Work'),
  NoteFolder('personal', 'Personal'),
  NoteFolder('ideas', 'Ideas'),
];

class Account {
  final String id;
  final String name;
  final String type;
  const Account(this.id, this.name, this.type);
}

const List<Account> kDefaultAccounts = [
  Account('cash', 'Cash', 'cash'),
  Account('bank', 'Bank', 'bank'),
  Account('credit', 'Credit Card', 'credit'),
  Account('wallet', 'Digital Wallet', 'wallet'),
];

const Map<String, String> kRecurrenceOptions = {
  'none': 'Once',
  'daily': 'Daily',
  'weekly': 'Weekly',
  'monthly': 'Monthly',
  'yearly': 'Yearly',
};

// Khata (Hisaab-Kitaab) constants
const Map<String, String> kKhataEntryTypes = {
  'given': 'Given (They Owe You)',
  'received': 'Received (You Owe Them)',
};

const Map<String, String> kDateFormats = {
  'yyyy-MM-dd': 'YYYY-MM-DD',
  'dd/MM/yyyy': 'DD/MM/YYYY',
  'MM/dd/yyyy': 'MM/DD/YYYY',
};

const Map<String, String> kFontSizes = {
  'small': 'Small',
  'default': 'Default',
  'large': 'Large',
};

const Map<String, double> kFontScaleFactors = {
  'small': 0.85,
  'default': 1.0,
  'large': 1.15,
};
