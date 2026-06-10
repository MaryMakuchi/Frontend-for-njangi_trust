import '../../domain/entities/contribution_entity.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/entities/group_entity.dart';
import '../../domain/entities/loan_entity.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/user_entity.dart';

class MockData {
  MockData._();

  static const UserEntity currentUser = UserEntity(
    id: 'user_001',
    fullName: 'Makuchi',
    email: 'makuchi@example.com',
    phone: '+237 6XX XXX XXX',
    mriScore: 9.4,
    isKycVerified: true,
    groupsCount: 3,
    yearsActive: 2,
    globalRank: 12,
    badge: 'Trusted Member',
  );

  static final DashboardEntity dashboard = DashboardEntity(
    njangiBalance: 1250000,
    totalContributions: 850000,
    nextPaymentDate: DateTime(2026, 7, 15),
    activeGroups: 3,
    pendingPayments: 1,
    totalSavings: 2450000,
    activeLoansAmount: 350000,
    socialFundBalance: 180000,
    currentPayout: 500000,
    mriScore: 9.4,
    mriTrend: 1.2,
    mriBreakdown: const MriBreakdownEntity(
      paymentPunctuality: 9.8,
      attendance: 9.2,
      loanRepayment: 9.5,
      contributionConsistency: 9.6,
      communityParticipation: 8.9,
    ),
    recentActivity: transactions.take(5).toList(),
  );

  static final List<GroupEntity> groups = [
    GroupEntity(
      id: 'grp_001',
      name: 'NJANGI HOUSE A',
      memberCount: 20,
      maxMembers: 20,
      contributionAmount: 50000,
      frequency: 'Monthly',
      fundBalance: 1000000,
      cycleProgress: 8,
      averageMri: 8.7,
      startDate: DateTime(2025, 1, 1),
      invitationCode: 'NJA2025',
      rules: 'Monthly contributions, rotation by join order.',
      currentBeneficiaryId: 'mem_003',
      nextBeneficiaryId: 'mem_004',
      members: _houseAMembers,
    ),
    GroupEntity(
      id: 'grp_002',
      name: 'FAMILY SAVERS',
      memberCount: 12,
      maxMembers: 15,
      contributionAmount: 25000,
      frequency: 'Bi-weekly',
      fundBalance: 300000,
      cycleProgress: 5,
      averageMri: 9.1,
      startDate: DateTime(2025, 6, 1),
      invitationCode: 'FAM2025',
      members: const [
        GroupMemberEntity(
          id: 'mem_101',
          name: 'Makuchi',
          role: GroupRole.president,
          mriScore: 9.4,
          rotationPosition: 1,
        ),
      ],
    ),
    GroupEntity(
      id: 'grp_003',
      name: 'YOUTH INVESTORS',
      memberCount: 8,
      maxMembers: 10,
      contributionAmount: 100000,
      frequency: 'Monthly',
      fundBalance: 800000,
      cycleProgress: 3,
      averageMri: 8.5,
      startDate: DateTime(2026, 1, 1),
      invitationCode: 'YTH2026',
      members: const [],
    ),
  ];

  static final List<GroupMemberEntity> _houseAMembers = [
    const GroupMemberEntity(
      id: 'mem_001',
      name: 'Makuchi',
      role: GroupRole.president,
      mriScore: 9.4,
      rotationPosition: 1,
    ),
    const GroupMemberEntity(
      id: 'mem_002',
      name: 'Amina K.',
      role: GroupRole.treasurer,
      mriScore: 9.1,
      rotationPosition: 2,
    ),
    const GroupMemberEntity(
      id: 'mem_003',
      name: 'Jean-Paul M.',
      role: GroupRole.member,
      mriScore: 8.9,
      isCurrentBeneficiary: true,
      rotationPosition: 3,
    ),
    const GroupMemberEntity(
      id: 'mem_004',
      name: 'Fatou S.',
      role: GroupRole.member,
      mriScore: 8.7,
      rotationPosition: 4,
    ),
    const GroupMemberEntity(
      id: 'mem_005',
      name: 'Samuel O.',
      role: GroupRole.member,
      mriScore: 8.5,
      rotationPosition: 5,
    ),
  ];

  static final List<ContributionEntity> contributions = [
    ContributionEntity(
      id: 'con_001',
      groupId: 'grp_001',
      groupName: 'NJANGI HOUSE A',
      amount: 50000,
      dueDate: DateTime(2026, 6, 1),
      status: ContributionStatus.completed,
      paidDate: DateTime(2026, 5, 28),
      paymentMethod: 'MTN MoMo',
    ),
    ContributionEntity(
      id: 'con_002',
      groupId: 'grp_002',
      groupName: 'FAMILY SAVERS',
      amount: 25000,
      dueDate: DateTime(2026, 6, 15),
      status: ContributionStatus.outstanding,
    ),
    ContributionEntity(
      id: 'con_003',
      groupId: 'grp_001',
      groupName: 'NJANGI HOUSE A',
      amount: 50000,
      dueDate: DateTime(2026, 5, 1),
      status: ContributionStatus.late,
    ),
  ];

  static final List<LoanEntity> loans = [
    LoanEntity(
      id: 'loan_001',
      amount: 350000,
      purpose: 'Business expansion',
      durationMonths: 6,
      status: LoanStatus.active,
      interestRate: 5.0,
      remainingBalance: 175000,
      dueDate: DateTime(2026, 9, 1),
      groupName: 'NJANGI HOUSE A',
      approvedDate: DateTime(2026, 3, 1),
    ),
    LoanEntity(
      id: 'loan_002',
      amount: 100000,
      purpose: 'Emergency medical',
      durationMonths: 3,
      status: LoanStatus.pending,
      interestRate: 3.0,
      groupName: 'FAMILY SAVERS',
    ),
    LoanEntity(
      id: 'loan_003',
      amount: 50000,
      purpose: 'School fees',
      durationMonths: 4,
      status: LoanStatus.repaid,
      interestRate: 4.0,
      remainingBalance: 0,
      groupName: 'YOUTH INVESTORS',
      approvedDate: DateTime(2025, 8, 1),
    ),
  ];

  static final List<TransactionEntity> transactions = [
    TransactionEntity(
      id: 'txn_001',
      title: 'Contribution - NJANGI HOUSE A',
      amount: 50000,
      type: TransactionType.contribution,
      status: TransactionStatus.verified,
      date: DateTime(2026, 5, 28),
      groupName: 'NJANGI HOUSE A',
      hash: '0x7a3f8b2c1d9e4f6a8b0c2d4e6f8a0b2c',
      isCredit: false,
    ),
    TransactionEntity(
      id: 'txn_002',
      title: 'Loan Repayment',
      amount: 58333,
      type: TransactionType.loanRepayment,
      status: TransactionStatus.completed,
      date: DateTime(2026, 5, 20),
      isCredit: false,
    ),
    TransactionEntity(
      id: 'txn_003',
      title: 'Payout Received',
      amount: 500000,
      type: TransactionType.payout,
      status: TransactionStatus.verified,
      date: DateTime(2026, 4, 15),
      groupName: 'FAMILY SAVERS',
      hash: '0x9b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e',
      isCredit: true,
    ),
    TransactionEntity(
      id: 'txn_004',
      title: 'Social Fund Contribution',
      amount: 10000,
      type: TransactionType.socialFund,
      status: TransactionStatus.completed,
      date: DateTime(2026, 5, 10),
      isCredit: false,
    ),
    TransactionEntity(
      id: 'txn_005',
      title: 'Contribution - FAMILY SAVERS',
      amount: 25000,
      type: TransactionType.contribution,
      status: TransactionStatus.verified,
      date: DateTime(2026, 5, 1),
      groupName: 'FAMILY SAVERS',
      hash: '0x1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d',
      isCredit: false,
    ),
  ];

  static final List<NotificationEntity> notifications = [
    NotificationEntity(
      id: 'notif_001',
      title: 'Payment Reminder',
      body: 'Your contribution to FAMILY SAVERS is due in 3 days.',
      type: NotificationType.paymentReminder,
      createdAt: DateTime(2026, 6, 5, 9, 0),
    ),
    NotificationEntity(
      id: 'notif_002',
      title: 'Loan Approved',
      body: 'Your loan request of 100,000 CFA has been approved.',
      type: NotificationType.loanApproval,
      createdAt: DateTime(2026, 6, 4, 14, 30),
    ),
    NotificationEntity(
      id: 'notif_003',
      title: 'Contribution Confirmed',
      body: 'Your payment of 50,000 CFA to NJANGI HOUSE A was verified.',
      type: NotificationType.contributionConfirmation,
      createdAt: DateTime(2026, 5, 28, 11, 15),
      isRead: true,
    ),
    NotificationEntity(
      id: 'notif_004',
      title: 'Upcoming Payout',
      body: 'Your payout from NJANGI HOUSE A is scheduled for July 15.',
      type: NotificationType.upcomingPayout,
      createdAt: DateTime(2026, 6, 1, 8, 0),
    ),
  ];

  static final List<Map<String, dynamic>> savingsChartData = [
    {'month': 'Jan', 'amount': 1800000.0},
    {'month': 'Feb', 'amount': 1950000.0},
    {'month': 'Mar', 'amount': 2100000.0},
    {'month': 'Apr', 'amount': 2200000.0},
    {'month': 'May', 'amount': 2350000.0},
    {'month': 'Jun', 'amount': 2450000.0},
  ];
}
