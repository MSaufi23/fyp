import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/review.dart';
import '../services/database_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import '../models/report.dart' as report_model;
import '../auth/map_picker_dialog.dart';

class AdminPage
    extends
        StatefulWidget {
  const AdminPage({
    super.key,
  });

  @override
  State<
    AdminPage
  >
  createState() =>
      _AdminPageState();
}

class _AdminPageState
    extends
        State<
          AdminPage
        >
    with
        SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<
    User
  >
  _users =
      [];
  List<
    report_model.Report
  >
  _reports =
      [];
  List<
    Review
  >
  _reviews =
      [];
  List<
    Map<
      String,
      dynamic
    >
  >
  _advertisements =
      [];
  UserType? _selectedUserType;
  final _searchController =
      TextEditingController();
  String _searchQuery =
      '';
  bool _isSuperAdmin =
      false;
  final _db =
      DatabaseService();
  bool _isLoadingReports =
      false;
  bool _isLoadingReviews =
      false;
  bool _isLoadingAdvertisements =
      false;

  // Analytics data
  Map<
    String,
    dynamic
  >
  _analytics =
      {};
  bool _isLoadingAnalytics =
      false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length:
          6,
      vsync:
          this,
    );
    _checkSuperAdmin();
    _fetchAllUsers();
    _loadReports();
    _loadReviews();
    _loadAdvertisements();
    _loadAnalytics();
  }

  Future<
    void
  >
  _checkSuperAdmin() async {
    final isSuper =
        await _db.isSuperAdmin();
    setState(
      () {
        _isSuperAdmin =
            isSuper;
      },
    );
  }

  Future<
    void
  >
  _fetchAllUsers() async {
    List<
      User
    >
    allUsers =
        [];

    // Fetch admins
    final adminSnap = DatabaseService.database.child(
      'users/admin',
    );
    final adminDataSnap =
        await adminSnap.get();
    if (adminDataSnap.exists) {
      final data =
          adminDataSnap.value
              as Map<
                dynamic,
                dynamic
              >;
      allUsers.addAll(
        data.entries.map(
          (
            entry,
          ) {
            final userData =
                entry.value
                    as Map<
                      dynamic,
                      dynamic
                    >;
            return User(
              username:
                  userData['username'],
              email:
                  userData['email'] ??
                  '',
              password:
                  userData['password'] ??
                  '',
              type:
                  UserType.admin,
            );
          },
        ),
      );
    }

    // Fetch businesses
    final businessUsers =
        await _db.getAllBusinesses();
    allUsers.addAll(
      businessUsers,
    );

    // Fetch normal users
    final normalSnap = DatabaseService.database.child(
      'users/normalUser',
    );
    final normalDataSnap =
        await normalSnap.get();
    if (normalDataSnap.exists) {
      final data =
          normalDataSnap.value
              as Map<
                dynamic,
                dynamic
              >;
      allUsers.addAll(
        data.entries.map(
          (
            entry,
          ) {
            final userData =
                entry.value
                    as Map<
                      dynamic,
                      dynamic
                    >;
            return User(
              username:
                  userData['username'],
              email:
                  userData['email'] ??
                  '',
              password:
                  userData['password'] ??
                  '',
              type:
                  UserType.user,
            );
          },
        ),
      );
    }

    setState(
      () {
        _users =
            allUsers;
      },
    );
  }

  List<
    User
  >
  get _filteredUsers {
    var filtered =
        _users;
    if (_selectedUserType !=
        null) {
      filtered =
          filtered
              .where(
                (
                  user,
                ) =>
                    user.type ==
                    _selectedUserType,
              )
              .toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (
                  user,
                ) =>
                    user.username.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    user.email.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    (user.businessName?.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ??
                        false),
              )
              .toList();
    }
    return filtered;
  }

  Future<
    void
  >
  _loadReports() async {
    setState(
      () {
        _isLoadingReports =
            true;
      },
    );

    try {
      final reports =
          await DatabaseService().getAllReports();
      setState(
        () {
          _reports =
              reports;
        },
      );
    } catch (
      e
    ) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading reports: $e',
            ),
            backgroundColor:
                Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(
          () {
            _isLoadingReports =
                false;
          },
        );
      }
    }
  }

  Future<
    void
  >
  _updateReportStatus(
    report_model.Report report,
    report_model.ReportStatus newStatus,
  ) async {
    try {
      await DatabaseService().updateReportStatus(
        report.id,
        newStatus,
      );
      await _loadReports();
      await _loadAnalytics(); // Refresh analytics after updating report status
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'Report status updated',
            ),
            backgroundColor:
                Colors.green,
          ),
        );
      }
    } catch (
      e
    ) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'Error updating report: $e',
            ),
            backgroundColor:
                Colors.red,
          ),
        );
      }
    }
  }

  Future<
    void
  >
  _showResponseDialog(
    report_model.Report report,
  ) async {
    final responseController =
        TextEditingController();
    return showDialog(
      context:
          context,
      builder:
          (
            context,
          ) => AlertDialog(
            title: const Text(
              'Add Response',
            ),
            content: TextField(
              controller:
                  responseController,
              maxLines:
                  3,
              decoration: const InputDecoration(
                hintText:
                    'Enter your response to the report...',
                border:
                    OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    () => Navigator.pop(
                      context,
                    ),
                child: const Text(
                  'Cancel',
                ),
              ),
              TextButton(
                onPressed: () async {
                  if (responseController.text.isNotEmpty) {
                    await DatabaseService().updateReportStatus(
                      report.id,
                      report_model.ReportStatus.resolved,
                      adminResponse:
                          responseController.text,
                    );
                    if (mounted) {
                      Navigator.pop(
                        context,
                      );
                      await _loadReports();
                      await _loadAnalytics(); // Refresh analytics after resolving report
                    }
                  }
                },
                child: const Text(
                  'Submit',
                ),
              ),
            ],
          ),
    );
  }

  Future<
    void
  >
  _loadReviews() async {
    setState(
      () {
        _isLoadingReviews =
            true;
      },
    );

    try {
      final reviews =
          await DatabaseService().getAllReviews();
      setState(
        () {
          _reviews =
              reviews;
        },
      );
    } catch (
      e
    ) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading reviews: $e',
            ),
            backgroundColor:
                Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(
          () {
            _isLoadingReviews =
                false;
          },
        );
      }
    }
  }

  Future<
    void
  >
  _loadAdvertisements() async {
    setState(
      () {
        _isLoadingAdvertisements =
            true;
      },
    );

    try {
      final advertisements =
          await DatabaseService().getAllAdvertisements();
      setState(
        () {
          _advertisements =
              advertisements;
        },
      );
    } catch (
      e
    ) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading advertisements: $e',
            ),
            backgroundColor:
                Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(
          () {
            _isLoadingAdvertisements =
                false;
          },
        );
      }
    }
  }

  Future<
    void
  >
  _loadAnalytics() async {
    setState(
      () {
        _isLoadingAnalytics =
            true;
      },
    );

    try {
      // Calculate analytics from existing data
      final analytics =
          await _calculateAnalytics();
      setState(
        () {
          _analytics =
              analytics;
          _isLoadingAnalytics =
              false;
        },
      );
    } catch (
      e
    ) {
      setState(
        () {
          _isLoadingAnalytics =
              false;
        },
      );
      print(
        'Error loading analytics: $e',
      );
    }
  }

  Future<
    Map<
      String,
      dynamic
    >
  >
  _calculateAnalytics() async {
    // User Analytics
    final totalUsers =
        _users.length;
    final normalUsers =
        _users
            .where(
              (
                u,
              ) =>
                  u.type ==
                  UserType.user,
            )
            .length;
    final businessUsers =
        _users
            .where(
              (
                u,
              ) =>
                  u.type ==
                  UserType.business,
            )
            .length;
    final adminUsers =
        _users
            .where(
              (
                u,
              ) =>
                  u.type ==
                  UserType.admin,
            )
            .length;

    // Business Analytics
    final businessesWithAds =
        businessUsers >
                0
            ? _users
                .where(
                  (
                    u,
                  ) =>
                      u.type ==
                          UserType.business &&
                      (u.advertisementImageUrl !=
                              null ||
                          u.advertisementTitle !=
                              null ||
                          u.advertisementDescription !=
                              null),
                )
                .length
            : 0;

    // Report Analytics
    final totalReports =
        _reports.length;
    final pendingReports =
        _reports
            .where(
              (
                r,
              ) =>
                  r.status ==
                  report_model.ReportStatus.pending,
            )
            .length;
    final resolvedReports =
        _reports
            .where(
              (
                r,
              ) =>
                  r.status ==
                  report_model.ReportStatus.resolved,
            )
            .length;
    final inProgressReports =
        _reports
            .where(
              (
                r,
              ) =>
                  r.status ==
                  report_model.ReportStatus.inProgress,
            )
            .length;
    final rejectedReports =
        _reports
            .where(
              (
                r,
              ) =>
                  r.status ==
                  report_model.ReportStatus.rejected,
            )
            .length;

    // Debug: Print report status counts
    print(
      'Analytics Debug - Total Reports: $totalReports',
    );
    print(
      'Analytics Debug - Pending: $pendingReports',
    );
    print(
      'Analytics Debug - In Progress: $inProgressReports',
    );
    print(
      'Analytics Debug - Resolved: $resolvedReports',
    );
    print(
      'Analytics Debug - Rejected: $rejectedReports',
    );

    // Debug: Print all report statuses
    for (
      int i = 0;
      i <
          _reports.length;
      i++
    ) {
      print(
        'Report $i: ${_reports[i].status}',
      );
    }

    return {
      'users': {
        'total':
            totalUsers,
        'normal':
            normalUsers,
        'business':
            businessUsers,
        'admin':
            adminUsers,
        'normalPercentage':
            totalUsers >
                    0
                ? (normalUsers /
                        totalUsers *
                        100)
                    .toStringAsFixed(
                      1,
                    )
                : '0',
        'businessPercentage':
            totalUsers >
                    0
                ? (businessUsers /
                        totalUsers *
                        100)
                    .toStringAsFixed(
                      1,
                    )
                : '0',
        'adminPercentage':
            totalUsers >
                    0
                ? (adminUsers /
                        totalUsers *
                        100)
                    .toStringAsFixed(
                      1,
                    )
                : '0',
      },
      'businesses': {
        'total':
            businessUsers,
        'withAds':
            businessesWithAds,
        'adsPercentage':
            businessUsers >
                    0
                ? (businessesWithAds /
                        businessUsers *
                        100)
                    .toStringAsFixed(
                      1,
                    )
                : '0',
      },
      'reports': {
        'total':
            totalReports,
        'pending':
            pendingReports,
        'inProgress':
            inProgressReports,
        'resolved':
            resolvedReports,
        'rejected':
            rejectedReports,
        'pendingPercentage':
            totalReports >
                    0
                ? (pendingReports /
                        totalReports *
                        100)
                    .toStringAsFixed(
                      1,
                    )
                : '0',
        'inProgressPercentage':
            totalReports >
                    0
                ? (inProgressReports /
                        totalReports *
                        100)
                    .toStringAsFixed(
                      1,
                    )
                : '0',
        'resolvedPercentage':
            totalReports >
                    0
                ? (resolvedReports /
                        totalReports *
                        100)
                    .toStringAsFixed(
                      1,
                    )
                : '0',
        'rejectedPercentage':
            totalReports >
                    0
                ? (rejectedReports /
                        totalReports *
                        100)
                    .toStringAsFixed(
                      1,
                    )
                : '0',
      },
    };
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        elevation:
            0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
            ),
            onPressed: () {
              _fetchAllUsers();
              _loadReports();
              _loadReviews();
              _loadAdvertisements();
              _loadAnalytics();
            },
            tooltip:
                'Refresh Data',
          ),
          IconButton(
            icon: const Icon(
              Icons.person_add,
            ),
            onPressed:
                _showAddUserDialog,
            tooltip:
                'Add User',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal:
                  8.0,
              vertical:
                  12.0,
            ),
            child: Card(
              elevation:
                  4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  24,
                ),
              ),
              margin:
                  EdgeInsets.zero,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    24,
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(
                        context,
                      ).primaryColor.withOpacity(
                        0.15,
                      ),
                      Theme.of(
                        context,
                      ).colorScheme.secondary.withOpacity(
                        0.10,
                      ),
                    ],
                    begin:
                        Alignment.topLeft,
                    end:
                        Alignment.bottomRight,
                  ),
                ),
                child: TabBar(
                  controller:
                      _tabController,
                  isScrollable:
                      true,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      50,
                    ),
                    color: Theme.of(
                      context,
                    ).primaryColor.withOpacity(
                      0.25,
                    ),
                  ),
                  labelColor:
                      Theme.of(
                        context,
                      ).primaryColor,
                  unselectedLabelColor:
                      Colors.grey,
                  labelStyle: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize:
                        16,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight:
                        FontWeight.normal,
                    fontSize:
                        15,
                  ),
                  labelPadding: const EdgeInsets.symmetric(
                    horizontal:
                        20,
                    vertical:
                        8,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(
                        Icons.analytics,
                      ),
                      text:
                          'Analytics',
                    ),
                    Tab(
                      icon: Icon(
                        Icons.people,
                      ),
                      text:
                          'Users',
                    ),
                    Tab(
                      icon: Icon(
                        Icons.report,
                      ),
                      text:
                          'Reports',
                    ),
                    Tab(
                      icon: Icon(
                        Icons.business,
                      ),
                      text:
                          'Businesses',
                    ),
                    Tab(
                      icon: Icon(
                        Icons.rate_review,
                      ),
                      text:
                          'Reviews',
                    ),
                    Tab(
                      icon: Icon(
                        Icons.campaign,
                      ),
                      text:
                          'Ads',
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller:
                  _tabController,
              children: [
                _buildAnalyticsTab(),
                _buildUsersTab(),
                _buildReportsTab(),
                _buildBusinessesTab(),
                _buildReviewsTab(),
                _buildAdvertisementsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(
            16.0,
          ),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).primaryColor.withOpacity(
              0.05,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(
                20,
              ),
              bottomRight: Radius.circular(
                20,
              ),
            ),
          ),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller:
                    _searchController,
                decoration: InputDecoration(
                  hintText:
                      'Search users...',
                  prefixIcon: const Icon(
                    Icons.search,
                  ),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                            ),
                            onPressed: () {
                              setState(
                                () {
                                  _searchController.clear();
                                  _searchQuery =
                                      '';
                                },
                              );
                            },
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      30,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                  filled:
                      true,
                  fillColor:
                      Colors.white,
                ),
                onChanged: (
                  value,
                ) {
                  setState(
                    () {
                      _searchQuery =
                          value;
                    },
                  );
                },
              ),
              const SizedBox(
                height:
                    16,
              ),
              // Filter Dropdown
              Row(
                children: [
                  const Text(
                    'Filter by type:',
                    style: TextStyle(
                      fontSize:
                          16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    width:
                        16,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal:
                          16,
                      vertical:
                          4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          Colors.white,
                      borderRadius: BorderRadius.circular(
                        20,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(
                            0.1,
                          ),
                          blurRadius:
                              4,
                          offset: const Offset(
                            0,
                            2,
                          ),
                        ),
                      ],
                    ),
                    child: DropdownButton<
                      UserType?
                    >(
                      value:
                          _selectedUserType,
                      hint: const Text(
                        'All Users',
                      ),
                      underline:
                          const SizedBox(),
                      items: [
                        const DropdownMenuItem<
                          UserType?
                        >(
                          value:
                              null,
                          child: Text(
                            'All Users',
                          ),
                        ),
                        ...UserType.values.map(
                          (
                            type,
                          ) => DropdownMenuItem<
                            UserType
                          >(
                            value:
                                type,
                            child: Row(
                              children: [
                                Icon(
                                  type ==
                                          UserType.business
                                      ? Icons.business
                                      : type ==
                                          UserType.admin
                                      ? Icons.admin_panel_settings
                                      : Icons.person,
                                  color: _getUserTypeColor(
                                    type,
                                  ),
                                  size:
                                      20,
                                ),
                                const SizedBox(
                                  width:
                                      8,
                                ),
                                Text(
                                  type.name.toUpperCase(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      onChanged: (
                        UserType? newValue,
                      ) {
                        setState(
                          () {
                            _selectedUserType =
                                newValue;
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child:
              _filteredUsers.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size:
                              64,
                          color:
                              Colors.grey[400],
                        ),
                        const SizedBox(
                          height:
                              16,
                        ),
                        Text(
                          'No users found',
                          style: TextStyle(
                            fontSize:
                                18,
                            color:
                                Colors.grey[600],
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    itemCount:
                        _filteredUsers.length,
                    itemBuilder: (
                      context,
                      index,
                    ) {
                      final user =
                          _filteredUsers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal:
                              16,
                          vertical:
                              8,
                        ),
                        elevation:
                            2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            15,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(
                            16,
                          ),
                          leading: CircleAvatar(
                            radius:
                                25,
                            backgroundColor: _getUserTypeColor(
                              user.type,
                            ),
                            child: Icon(
                              user.type ==
                                      UserType.business
                                  ? Icons.business
                                  : user.type ==
                                      UserType.admin
                                  ? Icons.admin_panel_settings
                                  : Icons.person,
                              color:
                                  Colors.white,
                              size:
                                  28,
                            ),
                          ),
                          title: Text(
                            user.username,
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                              fontSize:
                                  16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                height:
                                    4,
                              ),
                              Text(
                                user.email,
                                style: TextStyle(
                                  color:
                                      Colors.grey[600],
                                ),
                              ),
                              if (user.type ==
                                      UserType.business &&
                                  user.businessName !=
                                      null) ...[
                                const SizedBox(
                                  height:
                                      4,
                                ),
                                Text(
                                  'Business: ${user.businessName}',
                                  style: TextStyle(
                                    color:
                                        Colors.grey[600],
                                    fontStyle:
                                        FontStyle.italic,
                                  ),
                                ),
                              ],
                              if (user.type ==
                                      UserType.business &&
                                  user.businessLocation !=
                                      null) ...[
                                const SizedBox(
                                  height:
                                      4,
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size:
                                          14,
                                      color:
                                          Colors.green,
                                    ),
                                    const SizedBox(
                                      width:
                                          4,
                                    ),
                                    Text(
                                      'Location Set',
                                      style: TextStyle(
                                        color:
                                            Colors.green[600],
                                        fontSize:
                                            12,
                                        fontWeight:
                                            FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(
                                height:
                                    4,
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal:
                                      8,
                                  vertical:
                                      4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getUserTypeColor(
                                    user.type,
                                  ).withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    12,
                                  ),
                                ),
                                child: Text(
                                  user.type.name.toUpperCase(),
                                  style: TextStyle(
                                    color: _getUserTypeColor(
                                      user.type,
                                    ),
                                    fontWeight:
                                        FontWeight.bold,
                                    fontSize:
                                        12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            icon: const Icon(
                              Icons.more_vert,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                15,
                              ),
                            ),
                            itemBuilder:
                                (
                                  context,
                                ) => [
                                  const PopupMenuItem(
                                    value:
                                        'edit',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit,
                                          size:
                                              20,
                                        ),
                                        SizedBox(
                                          width:
                                              8,
                                        ),
                                        Text(
                                          'Edit',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value:
                                        'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          size:
                                              20,
                                          color:
                                              Colors.red,
                                        ),
                                        SizedBox(
                                          width:
                                              8,
                                        ),
                                        Text(
                                          'Delete',
                                          style: TextStyle(
                                            color:
                                                Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                            onSelected: (
                              value,
                            ) {
                              if (value ==
                                  'edit') {
                                _showEditUserDialog(
                                  user,
                                );
                              } else if (value ==
                                  'delete') {
                                _showDeleteConfirmation(
                                  user,
                                );
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Color _getUserTypeColor(
    UserType type,
  ) {
    switch (type) {
      case UserType.admin:
        return Colors.red;
      case UserType.business:
        return Colors.blue;
      case UserType.user:
        return Colors.green;
    }
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(
        16.0,
      ),
      child:
          _buildReportsSection(),
    );
  }

  Widget _buildReportsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          16.0,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Reports',
                  style: TextStyle(
                    fontSize:
                        20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                  ),
                  onPressed: () {
                    _loadReports();
                    _loadAnalytics(); // Refresh analytics when reports are refreshed
                  },
                ),
              ],
            ),
            const SizedBox(
              height:
                  16,
            ),
            if (_isLoadingReports)
              const Center(
                child:
                    CircularProgressIndicator(),
              )
            else if (_reports.isEmpty)
              const Center(
                child: Text(
                  'No reports yet',
                  style: TextStyle(
                    color:
                        Colors.grey,
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap:
                    true,
                physics:
                    const NeverScrollableScrollPhysics(),
                itemCount:
                    _reports.length,
                itemBuilder: (
                  context,
                  index,
                ) {
                  final report =
                      _reports[index];
                  return Card(
                    margin: const EdgeInsets.only(
                      bottom:
                          8.0,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(
                        16.0,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                report.statusText,
                                style: TextStyle(
                                  color:
                                      report.statusColor,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${report.timestamp.day}/${report.timestamp.month}/${report.timestamp.year}',
                                style: const TextStyle(
                                  color:
                                      Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height:
                                8,
                          ),
                          Text(
                            'From: ${report.reporterUsername} (${report.reporterType})',
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height:
                                8,
                          ),
                          Text(
                            report.content,
                          ),
                          if (report.adminResponse !=
                              null) ...[
                            const SizedBox(
                              height:
                                  8,
                            ),
                            const Divider(),
                            const Text(
                              'Admin Response:',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(
                              height:
                                  4,
                            ),
                            Text(
                              report.adminResponse!,
                            ),
                          ],
                          const SizedBox(
                            height:
                                16,
                          ),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.end,
                            children: [
                              if (report.status ==
                                  report_model.ReportStatus.pending) ...[
                                TextButton(
                                  onPressed:
                                      () => _updateReportStatus(
                                        report,
                                        report_model.ReportStatus.inProgress,
                                      ),
                                  child: const Text(
                                    'Mark In Progress',
                                  ),
                                ),
                                TextButton(
                                  onPressed:
                                      () => _updateReportStatus(
                                        report,
                                        report_model.ReportStatus.rejected,
                                      ),
                                  child: const Text(
                                    'Reject',
                                  ),
                                ),
                              ],
                              if (report.status ==
                                  report_model.ReportStatus.inProgress)
                                TextButton(
                                  onPressed:
                                      () => _showResponseDialog(
                                        report,
                                      ),
                                  child: const Text(
                                    'Add Response',
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color:
                                      Colors.red,
                                ),
                                tooltip:
                                    'Delete Report',
                                onPressed:
                                    () => _showDeleteReportConfirmation(
                                      report,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteReportConfirmation(
    report_model.Report report,
  ) {
    showDialog(
      context:
          context,
      builder:
          (
            context,
          ) => AlertDialog(
            title: const Text(
              'Delete Report',
            ),
            content: const Text(
              'Are you sure you want to delete this report?',
            ),
            actions: [
              TextButton(
                onPressed:
                    () =>
                        Navigator.of(
                          context,
                        ).pop(),
                child: const Text(
                  'Cancel',
                ),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await _db.deleteReport(
                      report.id,
                    );
                    if (mounted) {
                      Navigator.of(
                        context,
                      ).pop();
                      _loadReports();
                      _loadAnalytics(); // Refresh analytics after deleting report
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Report deleted successfully',
                          ),
                          backgroundColor:
                              Colors.green,
                        ),
                      );
                    }
                  } catch (
                    e
                  ) {
                    if (mounted) {
                      Navigator.of(
                        context,
                      ).pop();
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error deleting report: $e',
                          ),
                          backgroundColor:
                              Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor:
                      Colors.red,
                ),
                child: const Text(
                  'Delete',
                ),
              ),
            ],
          ),
    );
  }

  void _showAddAdminDialog() {
    final usernameController =
        TextEditingController();
    final emailController =
        TextEditingController();
    final passwordController =
        TextEditingController();

    showDialog(
      context:
          context,
      builder:
          (
            context,
          ) => AlertDialog(
            title: const Text(
              'Add New Admin',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  TextField(
                    controller:
                        usernameController,
                    decoration: const InputDecoration(
                      labelText:
                          'Username',
                    ),
                  ),
                  TextField(
                    controller:
                        emailController,
                    decoration: const InputDecoration(
                      labelText:
                          'Email',
                    ),
                  ),
                  TextField(
                    controller:
                        passwordController,
                    decoration: const InputDecoration(
                      labelText:
                          'Password',
                    ),
                    obscureText:
                        true,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    () => Navigator.pop(
                      context,
                    ),
                child: const Text(
                  'Cancel',
                ),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    final newAdmin = User(
                      username:
                          usernameController.text,
                      email:
                          emailController.text,
                      password:
                          passwordController.text,
                      type:
                          UserType.admin,
                    );
                    await _db.createAdminUser(
                      newAdmin,
                    );
                    if (mounted) {
                      Navigator.pop(
                        context,
                      );
                      _fetchAllUsers();
                      _loadAnalytics(); // Refresh analytics after adding admin
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Admin added successfully',
                          ),
                        ),
                      );
                    }
                  } catch (
                    e
                  ) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error adding admin: $e',
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Add',
                ),
              ),
            ],
          ),
    );
  }

  void _showEditUserDialog(
    User user,
  ) {
    final usernameController = TextEditingController(
      text:
          user.username,
    );
    final emailController = TextEditingController(
      text:
          user.email,
    );
    final businessNameController = TextEditingController(
      text:
          user.businessName,
    );
    final businessAddressController = TextEditingController(
      text:
          user.businessAddress,
    );
    LatLng? selectedLocation =
        user.businessLocation;

    showDialog(
      context:
          context,
      builder:
          (
            context,
          ) => AlertDialog(
            title: const Text(
              'Edit User',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  TextField(
                    controller:
                        usernameController,
                    decoration: const InputDecoration(
                      labelText:
                          'Username',
                    ),
                  ),
                  TextField(
                    controller:
                        emailController,
                    decoration: const InputDecoration(
                      labelText:
                          'Email',
                    ),
                  ),
                  if (user.type ==
                      UserType.business) ...[
                    TextField(
                      controller:
                          businessNameController,
                      decoration: const InputDecoration(
                        labelText:
                            'Business Name',
                      ),
                    ),
                    TextField(
                      controller:
                          businessAddressController,
                      decoration: const InputDecoration(
                        labelText:
                            'Business Address',
                      ),
                    ),
                    const SizedBox(
                      height:
                          16,
                    ),
                    // Business Location Section
                    const Text(
                      'Business Location',
                      style: TextStyle(
                        fontSize:
                            16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height:
                          8,
                    ),
                    // Current Location Display
                    if (selectedLocation !=
                        null)
                      Container(
                        padding: const EdgeInsets.all(
                          8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              Colors.grey[100],
                          borderRadius: BorderRadius.circular(
                            8,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color:
                                  Colors.green,
                            ),
                            const SizedBox(
                              width:
                                  8,
                            ),
                            Expanded(
                              child: Text(
                                'Lat: ${selectedLocation!.latitude.toStringAsFixed(6)}, Lng: ${selectedLocation!.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  fontSize:
                                      12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(
                      height:
                          8,
                    ),
                    // Map Picker Button
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await showDialog<
                          LatLng
                        >(
                          context:
                              context,
                          builder:
                              (
                                context,
                              ) => MapPickerDialog(
                                initialLocation:
                                    selectedLocation ??
                                    const LatLng(
                                      2.1896,
                                      102.2501,
                                    ),
                                onLocationSelected: (
                                  location,
                                ) {
                                  selectedLocation =
                                      location;
                                },
                              ),
                        );
                        if (result !=
                            null) {
                          selectedLocation =
                              result;
                        }
                      },
                      icon: const Icon(
                        Icons.map,
                      ),
                      label: const Text(
                        'Pick Location on Map',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.blue,
                        foregroundColor:
                            Colors.white,
                      ),
                    ),
                    const SizedBox(
                      height:
                          8,
                    ),
                    // Clear Location Button
                    if (selectedLocation !=
                        null)
                      ElevatedButton.icon(
                        onPressed: () {
                          selectedLocation =
                              null;
                        },
                        icon: const Icon(
                          Icons.clear,
                        ),
                        label: const Text(
                          'Clear Location',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.red,
                          foregroundColor:
                              Colors.white,
                        ),
                      ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    () => Navigator.pop(
                      context,
                    ),
                child: const Text(
                  'Cancel',
                ),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    final Map<
                      String,
                      dynamic
                    >
                    updates = {
                      'username':
                          usernameController.text,
                      'email':
                          emailController.text,
                    };

                    if (user.type ==
                        UserType.business) {
                      updates['businessName'] =
                          businessNameController.text;
                      updates['businessAddress'] =
                          businessAddressController.text;
                      if (selectedLocation !=
                          null) {
                        updates['businessLocation'] = {
                          'latitude':
                              selectedLocation!.latitude,
                          'longitude':
                              selectedLocation!.longitude,
                        };
                      } else {
                        // Remove business location if cleared
                        updates['businessLocation'] =
                            null;
                      }
                    }

                    await _db.updateUserByType(
                      user.username,
                      user.type,
                      updates,
                    );
                    if (mounted) {
                      Navigator.pop(
                        context,
                      );
                      _fetchAllUsers();
                      _loadAnalytics(); // Refresh analytics after updating user
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'User updated successfully',
                          ),
                        ),
                      );
                    }
                  } catch (
                    e
                  ) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error updating user: $e',
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Save',
                ),
              ),
            ],
          ),
    );
  }

  void _showDeleteConfirmation(
    User user,
  ) {
    showDialog(
      context:
          context,
      builder:
          (
            context,
          ) => AlertDialog(
            title: const Text(
              'Delete User',
            ),
            content: Text(
              'Are you sure you want to delete ${user.username}?',
            ),
            actions: [
              TextButton(
                onPressed:
                    () => Navigator.pop(
                      context,
                    ),
                child: const Text(
                  'Cancel',
                ),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await _db.deleteUserByType(
                      user.username,
                      user.type,
                    );
                    if (mounted) {
                      Navigator.pop(
                        context,
                      );
                      _fetchAllUsers();
                      _loadAnalytics(); // Refresh analytics after deleting user
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'User deleted successfully',
                          ),
                        ),
                      );
                    }
                  } catch (
                    e
                  ) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error deleting user: $e',
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Delete',
                ),
              ),
            ],
          ),
    );
  }

  // Add User Dialog
  void _showAddUserDialog() {
    final usernameController =
        TextEditingController();
    final emailController =
        TextEditingController();
    final passwordController =
        TextEditingController();
    final businessNameController =
        TextEditingController();
    final businessDescriptionController =
        TextEditingController();
    final businessAddressController =
        TextEditingController();
    final businessPhoneController =
        TextEditingController();
    final businessEmailController =
        TextEditingController();
    TimeOfDay? openingTime;
    TimeOfDay? closingTime;
    LatLng? businessLocation;
    UserType selectedType =
        UserType.user;
    final formKey =
        GlobalKey<
          FormState
        >();

    Future<
      void
    >
    pickTime(
      BuildContext context,
      bool isOpening,
      void Function(
        void Function(),
      )
      setState,
    ) async {
      final picked = await showTimePicker(
        context:
            context,
        initialTime:
            isOpening
                ? (openingTime ??
                    TimeOfDay(
                      hour:
                          9,
                      minute:
                          0,
                    ))
                : (closingTime ??
                    TimeOfDay(
                      hour:
                          17,
                      minute:
                          0,
                    )),
      );
      if (picked !=
          null) {
        setState(
          () {
            if (isOpening) {
              openingTime =
                  picked;
            } else {
              closingTime =
                  picked;
            }
          },
        );
      }
    }

    Future<
      void
    >
    pickLocation(
      BuildContext context,
      void Function(
        void Function(),
      )
      setState,
    ) async {
      LatLng selected =
          businessLocation ??
          const LatLng(
            2.1896,
            102.2501,
          );
      final result = await showDialog<
        LatLng
      >(
        context:
            context,
        builder: (
          context,
        ) {
          final mapController =
              MapController();
          return AlertDialog(
            title: const Text(
              'Select Business Location',
            ),
            content: SizedBox(
              width:
                  MediaQuery.of(
                    context,
                  ).size.width *
                  0.8,
              height:
                  MediaQuery.of(
                    context,
                  ).size.height *
                  0.5,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController:
                        mapController,
                    options: MapOptions(
                      initialCenter:
                          selected,
                      initialZoom:
                          15,
                      onTap: (
                        tapPosition,
                        point,
                      ) {
                        selected =
                            point;
                        mapController.move(
                          point,
                          mapController.camera.zoom,
                        );
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'FYP_App/1.0',
                        subdomains: const [
                          'a',
                          'b',
                          'c',
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            width:
                                60.0,
                            height:
                                60.0,
                            point:
                                selected,
                            child: const Icon(
                              Icons.location_on,
                              color:
                                  Colors.red,
                              size:
                                  36,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    () =>
                        Navigator.of(
                          context,
                        ).pop(),
                child: const Text(
                  'Cancel',
                ),
              ),
              ElevatedButton(
                onPressed:
                    () => Navigator.of(
                      context,
                    ).pop(
                      selected,
                    ),
                child: const Text(
                  'Select',
                ),
              ),
            ],
          );
        },
      );
      if (result !=
          null) {
        setState(
          () {
            businessLocation =
                result;
          },
        );
        // Reverse geocode to get human-readable address
        try {
          List<
            Placemark
          >
          placemarks = await placemarkFromCoordinates(
            result.latitude,
            result.longitude,
          );
          if (placemarks.isNotEmpty) {
            final place =
                placemarks.first;
            final address = [
                  if (place.street !=
                          null &&
                      place.street!.isNotEmpty)
                    place.street,
                  if (place.subLocality !=
                          null &&
                      place.subLocality!.isNotEmpty)
                    place.subLocality,
                  if (place.locality !=
                          null &&
                      place.locality!.isNotEmpty)
                    place.locality,
                  if (place.postalCode !=
                          null &&
                      place.postalCode!.isNotEmpty)
                    place.postalCode,
                  if (place.country !=
                          null &&
                      place.country!.isNotEmpty)
                    place.country,
                ]
                .whereType<
                  String
                >()
                .join(
                  ', ',
                );
            setState(
              () {
                businessAddressController.text = address;
              },
            );
          } else {
            setState(
              () {
                businessAddressController.text = '${result.latitude}, ${result.longitude}';
              },
            );
          }
        } catch (
          e
        ) {
          setState(
            () {
              businessAddressController.text = '${result.latitude}, ${result.longitude}';
            },
          );
        }
      }
    }

    showDialog(
      context:
          context,
      builder:
          (
            context,
          ) => StatefulBuilder(
            builder:
                (
                  context,
                  setState,
                ) => AlertDialog(
                  title: const Text(
                    'Add New User',
                  ),
                  content: SingleChildScrollView(
                    child: Form(
                      key:
                          formKey,
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<
                            UserType
                          >(
                            value:
                                selectedType,
                            items: [
                              DropdownMenuItem(
                                value:
                                    UserType.user,
                                child: Text(
                                  'Normal User',
                                ),
                              ),
                              DropdownMenuItem(
                                value:
                                    UserType.business,
                                child: Text(
                                  'Business Owner',
                                ),
                              ),
                              DropdownMenuItem(
                                value:
                                    UserType.admin,
                                child: Text(
                                  'Admin',
                                ),
                              ),
                            ],
                            onChanged: (
                              val,
                            ) {
                              if (val !=
                                  null) {
                                setState(
                                  () {
                                    selectedType =
                                        val;
                                  },
                                );
                              }
                            },
                            decoration: const InputDecoration(
                              labelText:
                                  'User Type',
                            ),
                          ),
                          TextFormField(
                            controller:
                                usernameController,
                            decoration: const InputDecoration(
                              labelText:
                                  'Username',
                            ),
                            validator:
                                (
                                  v,
                                ) =>
                                    v ==
                                                null ||
                                            v.isEmpty
                                        ? 'Required'
                                        : null,
                          ),
                          TextFormField(
                            controller:
                                emailController,
                            decoration: const InputDecoration(
                              labelText:
                                  'Email',
                            ),
                            validator:
                                (
                                  v,
                                ) =>
                                    v ==
                                                null ||
                                            v.isEmpty
                                        ? 'Required'
                                        : null,
                          ),
                          TextFormField(
                            controller:
                                passwordController,
                            decoration: const InputDecoration(
                              labelText:
                                  'Password',
                            ),
                            obscureText:
                                true,
                            validator:
                                (
                                  v,
                                ) =>
                                    v ==
                                                null ||
                                            v.isEmpty
                                        ? 'Required'
                                        : null,
                          ),
                          if (selectedType ==
                              UserType.business) ...[
                            TextFormField(
                              controller:
                                  businessNameController,
                              decoration: const InputDecoration(
                                labelText:
                                    'Business Name',
                              ),
                              validator:
                                  (
                                    v,
                                  ) =>
                                      v ==
                                                  null ||
                                              v.isEmpty
                                          ? 'Required'
                                          : null,
                            ),
                            TextFormField(
                              controller:
                                  businessDescriptionController,
                              decoration: const InputDecoration(
                                labelText:
                                    'Business Description',
                              ),
                            ),
                            TextFormField(
                              controller:
                                  businessAddressController,
                              decoration: InputDecoration(
                                labelText:
                                    'Business Address',
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.map,
                                  ),
                                  onPressed:
                                      () => pickLocation(
                                        context,
                                        setState,
                                      ),
                                ),
                              ),
                            ),
                            TextFormField(
                              controller:
                                  businessPhoneController,
                              decoration: const InputDecoration(
                                labelText:
                                    'Business Phone',
                              ),
                            ),
                            TextFormField(
                              controller:
                                  businessEmailController,
                              decoration: const InputDecoration(
                                labelText:
                                    'Business Email',
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    readOnly:
                                        true,
                                    decoration: InputDecoration(
                                      labelText:
                                          'Opening Time',
                                      suffixIcon: IconButton(
                                        icon: const Icon(
                                          Icons.access_time,
                                        ),
                                        onPressed:
                                            () => pickTime(
                                              context,
                                              true,
                                              setState,
                                            ),
                                      ),
                                    ),
                                    controller: TextEditingController(
                                      text:
                                          openingTime !=
                                                  null
                                              ? openingTime!.format(
                                                context,
                                              )
                                              : '',
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width:
                                      8,
                                ),
                                Expanded(
                                  child: TextFormField(
                                    readOnly:
                                        true,
                                    decoration: InputDecoration(
                                      labelText:
                                          'Closing Time',
                                      suffixIcon: IconButton(
                                        icon: const Icon(
                                          Icons.access_time,
                                        ),
                                        onPressed:
                                            () => pickTime(
                                              context,
                                              false,
                                              setState,
                                            ),
                                      ),
                                    ),
                                    controller: TextEditingController(
                                      text:
                                          closingTime !=
                                                  null
                                              ? closingTime!.format(
                                                context,
                                              )
                                              : '',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          () => Navigator.pop(
                            context,
                          ),
                      child: const Text(
                        'Cancel',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        try {
                          if (selectedType ==
                              UserType.admin) {
                            final newAdmin = User(
                              username:
                                  usernameController.text,
                              email:
                                  emailController.text,
                              password:
                                  passwordController.text,
                              type:
                                  UserType.admin,
                            );
                            await _db.createAdminUser(
                              newAdmin,
                            );
                          } else if (selectedType ==
                              UserType.business) {
                            final newBusiness = User(
                              username:
                                  usernameController.text,
                              email:
                                  emailController.text,
                              password:
                                  passwordController.text,
                              type:
                                  UserType.business,
                              businessName:
                                  businessNameController.text,
                              businessDescription:
                                  businessDescriptionController.text,
                              businessAddress:
                                  businessAddressController.text,
                              businessPhone:
                                  businessPhoneController.text,
                              businessEmail:
                                  businessEmailController.text,
                              openingTime:
                                  openingTime,
                              closingTime:
                                  closingTime,
                              businessLocation:
                                  businessLocation,
                            );
                            await _db.createUser(
                              newBusiness,
                            );
                          } else {
                            final newUser = User(
                              username:
                                  usernameController.text,
                              email:
                                  emailController.text,
                              password:
                                  passwordController.text,
                              type:
                                  UserType.user,
                            );
                            await _db.createUser(
                              newUser,
                            );
                          }
                          if (mounted) {
                            Navigator.pop(
                              context,
                            );
                            _fetchAllUsers();
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'User added successfully',
                                ),
                                backgroundColor:
                                    Colors.green,
                              ),
                            );
                          }
                        } catch (
                          e
                        ) {
                          if (mounted) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Error adding user: $e',
                                ),
                                backgroundColor:
                                    Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'Add',
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildAnalyticsTab() {
    if (_isLoadingAnalytics) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(
        16.0,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Platform Analytics',
            style: TextStyle(
              fontSize:
                  24,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          const SizedBox(
            height:
                24,
          ),

          // User Analytics
          _buildAnalyticsCard(
            title:
                'User Analytics',
            icon:
                Icons.people,
            color:
                Colors.blue,
            children: [
              _buildAnalyticsRow(
                'Total Users',
                '${_analytics['users']?['total'] ?? 0}',
              ),
              _buildAnalyticsRow(
                'Normal Users',
                '${_analytics['users']?['normal'] ?? 0} (${_analytics['users']?['normalPercentage'] ?? 0}%)',
              ),
              _buildAnalyticsRow(
                'Business Users',
                '${_analytics['users']?['business'] ?? 0} (${_analytics['users']?['businessPercentage'] ?? 0}%)',
              ),
              _buildAnalyticsRow(
                'Admin Users',
                '${_analytics['users']?['admin'] ?? 0} (${_analytics['users']?['adminPercentage'] ?? 0}%)',
              ),
            ],
          ),

          const SizedBox(
            height:
                16,
          ),

          // Business Analytics
          _buildAnalyticsCard(
            title:
                'Business Analytics',
            icon:
                Icons.business,
            color:
                Colors.green,
            children: [
              _buildAnalyticsRow(
                'Total Businesses',
                '${_analytics['businesses']?['total'] ?? 0}',
              ),
              _buildAnalyticsRow(
                'Businesses with Ads',
                '${_analytics['businesses']?['withAds'] ?? 0}',
              ),
              _buildAnalyticsRow(
                'Ad Adoption Rate',
                '${_analytics['businesses']?['adsPercentage'] ?? 0}%',
              ),
            ],
          ),

          const SizedBox(
            height:
                16,
          ),

          // Report Analytics
          _buildAnalyticsCard(
            title:
                'Report Analytics',
            icon:
                Icons.report,
            color:
                Colors.orange,
            children: [
              _buildAnalyticsRow(
                'Total Reports',
                '${_analytics['reports']?['total'] ?? 0}',
              ),
              _buildAnalyticsRow(
                'Pending Reports',
                '${_analytics['reports']?['pending'] ?? 0} (${_analytics['reports']?['pendingPercentage'] ?? 0}%)',
                color:
                    Colors.orange,
              ),
              _buildAnalyticsRow(
                'In Progress Reports',
                '${_analytics['reports']?['inProgress'] ?? 0} (${_analytics['reports']?['inProgressPercentage'] ?? 0}%)',
                color:
                    Colors.blue,
              ),
              _buildAnalyticsRow(
                'Resolved Reports',
                '${_analytics['reports']?['resolved'] ?? 0} (${_analytics['reports']?['resolvedPercentage'] ?? 0}%)',
                color:
                    Colors.green,
              ),
              _buildAnalyticsRow(
                'Rejected Reports',
                '${_analytics['reports']?['rejected'] ?? 0} (${_analytics['reports']?['rejectedPercentage'] ?? 0}%)',
                color:
                    Colors.red,
              ),
            ],
          ),

          const SizedBox(
            height:
                16,
          ),

          // Quick Actions
          _buildAnalyticsCard(
            title:
                'Quick Actions',
            icon:
                Icons.speed,
            color:
                Colors.purple,
            children: [
              _buildActionButton(
                'View All Users',
                Icons.people,
                () => _tabController.animateTo(
                  1,
                ),
              ),
              _buildActionButton(
                'View Reports',
                Icons.report,
                () => _tabController.animateTo(
                  2,
                ),
              ),
              _buildActionButton(
                'View Businesses',
                Icons.business,
                () => _tabController.animateTo(
                  3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<
      Widget
    >
    children,
  }) {
    return Card(
      elevation:
          4,
      child: Padding(
        padding: const EdgeInsets.all(
          16.0,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color:
                      color,
                  size:
                      24,
                ),
                const SizedBox(
                  width:
                      8,
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize:
                        18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height:
                  16,
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsRow(
    String label,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical:
            4.0,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize:
                  14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize:
                  14,
              fontWeight:
                  FontWeight.bold,
              color:
                  color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical:
            4.0,
      ),
      child: SizedBox(
        width:
            double.infinity,
        child: ElevatedButton.icon(
          onPressed:
              onPressed,
          icon: Icon(
            icon,
            size:
                16,
          ),
          label: Text(
            label,
          ),
          style: ElevatedButton.styleFrom(
            alignment:
                Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(
              horizontal:
                  16,
              vertical:
                  12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessesTab() {
    final businesses =
        _users
            .where(
              (
                user,
              ) =>
                  user.type ==
                  UserType.business,
            )
            .toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(
            16.0,
          ),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).primaryColor.withOpacity(
              0.05,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(
                20,
              ),
              bottomRight: Radius.circular(
                20,
              ),
            ),
          ),
          child: Column(
            children: [
              Text(
                'Business Management',
                style: TextStyle(
                  fontSize:
                      20,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Theme.of(
                        context,
                      ).primaryColor,
                ),
              ),
              const SizedBox(
                height:
                    8,
              ),
              Text(
                'Total Businesses: ${businesses.length}',
                style: const TextStyle(
                  fontSize:
                      16,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              businesses.isEmpty
                  ? const Center(
                    child: Text(
                      'No businesses found',
                      style: TextStyle(
                        fontSize:
                            16,
                        color:
                            Colors.grey,
                      ),
                    ),
                  )
                  : ListView.builder(
                    itemCount:
                        businesses.length,
                    itemBuilder: (
                      context,
                      index,
                    ) {
                      final business =
                          businesses[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal:
                              16,
                          vertical:
                              4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                Colors.blue.shade100,
                            child:
                                business.profilePictureUrl !=
                                        null
                                    ? ClipOval(
                                      child: Image.network(
                                        business.profilePictureUrl!,
                                        width:
                                            40,
                                        height:
                                            40,
                                        fit:
                                            BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Text(
                                            business.profileEmoji ??
                                                '🏢',
                                            style: const TextStyle(
                                              fontSize:
                                                  20,
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                    : Text(
                                      business.profileEmoji ??
                                          '🏢',
                                      style: const TextStyle(
                                        fontSize:
                                            20,
                                      ),
                                    ),
                          ),
                          title: Text(
                            business.businessName ??
                                'Unknown Business',
                          ),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                business.businessAddress ??
                                    'No address',
                              ),
                              if (business.advertisementTitle !=
                                  null)
                                Container(
                                  margin: const EdgeInsets.only(
                                    top:
                                        4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal:
                                        8,
                                    vertical:
                                        2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.orange,
                                    borderRadius: BorderRadius.circular(
                                      12,
                                    ),
                                  ),
                                  child: const Text(
                                    'Has Advertisement',
                                    style: TextStyle(
                                      color:
                                          Colors.white,
                                      fontSize:
                                          10,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: PopupMenuButton<
                            String
                          >(
                            onSelected: (
                              value,
                            ) {
                              if (value ==
                                  'view') {
                                _showBusinessDetails(
                                  business,
                                );
                              } else if (value ==
                                  'delete') {
                                _showDeleteBusinessConfirmation(
                                  business,
                                );
                              }
                            },
                            itemBuilder:
                                (
                                  context,
                                ) => [
                                  const PopupMenuItem(
                                    value:
                                        'view',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.visibility,
                                        ),
                                        SizedBox(
                                          width:
                                              8,
                                        ),
                                        Text(
                                          'View Details',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value:
                                        'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          color:
                                              Colors.red,
                                        ),
                                        SizedBox(
                                          width:
                                              8,
                                        ),
                                        Text(
                                          'Delete',
                                          style: TextStyle(
                                            color:
                                                Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  void _showBusinessDetails(
    User business,
  ) {
    showDialog(
      context:
          context,
      builder:
          (
            context,
          ) => AlertDialog(
            title: Text(
              business.businessName ??
                  'Business Details',
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  if (business.businessDescription !=
                      null) ...[
                    const Text(
                      'Description:',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    Text(
                      business.businessDescription!,
                    ),
                    const SizedBox(
                      height:
                          16,
                    ),
                  ],
                  if (business.businessAddress !=
                      null) ...[
                    const Text(
                      'Address:',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    Text(
                      business.businessAddress!,
                    ),
                    const SizedBox(
                      height:
                          16,
                    ),
                  ],
                  if (business.businessPhone !=
                      null) ...[
                    const Text(
                      'Phone:',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    Text(
                      business.businessPhone!,
                    ),
                    const SizedBox(
                      height:
                          16,
                    ),
                  ],
                  if (business.businessEmail !=
                      null) ...[
                    const Text(
                      'Email:',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    Text(
                      business.businessEmail!,
                    ),
                    const SizedBox(
                      height:
                          16,
                    ),
                  ],
                  if (business.advertisementTitle !=
                      null) ...[
                    const Text(
                      'Advertisement:',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    Text(
                      business.advertisementTitle!,
                    ),
                    if (business.advertisementDescription !=
                        null) ...[
                      const SizedBox(
                        height:
                            8,
                      ),
                      Text(
                        business.advertisementDescription!,
                      ),
                    ],
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    () =>
                        Navigator.of(
                          context,
                        ).pop(),
                child: const Text(
                  'Close',
                ),
              ),
            ],
          ),
    );
  }

  void _showDeleteBusinessConfirmation(
    User business,
  ) {
    showDialog(
      context:
          context,
      builder:
          (
            context,
          ) => AlertDialog(
            title: const Text(
              'Delete Business',
            ),
            content: Text(
              'Are you sure you want to delete ${business.businessName ?? 'this business'}?',
            ),
            actions: [
              TextButton(
                onPressed:
                    () =>
                        Navigator.of(
                          context,
                        ).pop(),
                child: const Text(
                  'Cancel',
                ),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await _db.deleteUserByType(
                      business.username,
                      business.type,
                    );
                    if (mounted) {
                      Navigator.of(
                        context,
                      ).pop();
                      _fetchAllUsers();
                      _loadAnalytics();
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Business deleted successfully',
                          ),
                        ),
                      );
                    }
                  } catch (
                    e
                  ) {
                    if (mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error deleting business: $e',
                          ),
                        ),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor:
                      Colors.red,
                ),
                child: const Text(
                  'Delete',
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildReviewsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(
            16.0,
          ),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).primaryColor.withOpacity(
              0.05,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(
                20,
              ),
              bottomRight: Radius.circular(
                20,
              ),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.rate_review,
                color:
                    Colors.blue,
              ),
              const SizedBox(
                width:
                    8,
              ),
              const Text(
                'Reviews Management',
                style: TextStyle(
                  fontSize:
                      18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_reviews.length} reviews',
                style: const TextStyle(
                  fontSize:
                      14,
                  color:
                      Colors.grey,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              _isLoadingReviews
                  ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                  : _reviews.isEmpty
                  ? const Center(
                    child: Text(
                      'No reviews found',
                      style: TextStyle(
                        fontSize:
                            16,
                        color:
                            Colors.grey,
                      ),
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.all(
                      16,
                    ),
                    itemCount:
                        _reviews.length,
                    itemBuilder: (
                      context,
                      index,
                    ) {
                      final review =
                          _reviews[index];
                      return Card(
                        margin: const EdgeInsets.only(
                          bottom:
                              12,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                Colors.blue,
                            child: Text(
                              review.reviewerUsername[0].toUpperCase(),
                              style: const TextStyle(
                                color:
                                    Colors.white,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            review.reviewerUsername,
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Business: ${review.businessUsername}',
                              ),
                              const SizedBox(
                                height:
                                    4,
                              ),
                              Row(
                                children: List.generate(
                                  5,
                                  (
                                    starIndex,
                                  ) {
                                    return Icon(
                                      starIndex <
                                              review.rating
                                          ? Icons.star
                                          : Icons.star_border,
                                      color:
                                          Colors.amber,
                                      size:
                                          16,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(
                                height:
                                    4,
                              ),
                              Text(
                                review.comment,
                              ),
                              const SizedBox(
                                height:
                                    4,
                              ),
                              Text(
                                '${review.timestamp.day}/${review.timestamp.month}/${review.timestamp.year}',
                                style: const TextStyle(
                                  fontSize:
                                      12,
                                  color:
                                      Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<
                            String
                          >(
                            onSelected: (
                              value,
                            ) async {
                              if (value ==
                                  'delete') {
                                _showDeleteReviewConfirmation(
                                  review,
                                );
                              }
                            },
                            itemBuilder:
                                (
                                  context,
                                ) => [
                                  const PopupMenuItem(
                                    value:
                                        'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          color:
                                              Colors.red,
                                        ),
                                        SizedBox(
                                          width:
                                              8,
                                        ),
                                        Text(
                                          'Delete Review',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildAdvertisementsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(
            16.0,
          ),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).primaryColor.withOpacity(
              0.05,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(
                20,
              ),
              bottomRight: Radius.circular(
                20,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.campaign,
                    color:
                        Colors.blue,
                  ),
                  const SizedBox(
                    width:
                        8,
                  ),
                  const Text(
                    'Advertisements Management',
                    style: TextStyle(
                      fontSize:
                          18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height:
                    4,
              ),
              Text(
                '${_advertisements.length} advertisements',
                style: const TextStyle(
                  fontSize:
                      14,
                  color:
                      Colors.grey,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              _isLoadingAdvertisements
                  ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                  : _advertisements.isEmpty
                  ? const Center(
                    child: Text(
                      'No advertisements found',
                      style: TextStyle(
                        fontSize:
                            16,
                        color:
                            Colors.grey,
                      ),
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.all(
                      16,
                    ),
                    itemCount:
                        _advertisements.length,
                    itemBuilder: (
                      context,
                      index,
                    ) {
                      final advertisement =
                          _advertisements[index];
                      return Card(
                        margin: const EdgeInsets.only(
                          bottom:
                              12,
                        ),
                        child: ListTile(
                          leading:
                              advertisement['advertisementImageUrl'] !=
                                      null
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      8,
                                    ),
                                    child: Image.network(
                                      advertisement['advertisementImageUrl'],
                                      width:
                                          60,
                                      height:
                                          60,
                                      fit:
                                          BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Container(
                                          width:
                                              60,
                                          height:
                                              60,
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.grey[300],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.image_not_supported,
                                            color:
                                                Colors.grey,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                  : Container(
                                    width:
                                        60,
                                    height:
                                        60,
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.grey[300],
                                      borderRadius: BorderRadius.circular(
                                        8,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.campaign,
                                      color:
                                          Colors.grey,
                                    ),
                                  ),
                          title: Text(
                            advertisement['businessName'] ??
                                'Unknown Business',
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                            maxLines:
                                1,
                            overflow:
                                TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Business: ${advertisement['username']}',
                                maxLines:
                                    1,
                                overflow:
                                    TextOverflow.ellipsis,
                              ),
                              if (advertisement['advertisementTitle'] !=
                                  null) ...[
                                const SizedBox(
                                  height:
                                      4,
                                ),
                                Text(
                                  advertisement['advertisementTitle'],
                                  style: const TextStyle(
                                    fontWeight:
                                        FontWeight.w500,
                                  ),
                                  maxLines:
                                      1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                              ],
                              if (advertisement['advertisementDescription'] !=
                                  null) ...[
                                const SizedBox(
                                  height:
                                      4,
                                ),
                                Text(
                                  advertisement['advertisementDescription'],
                                  maxLines:
                                      2,
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                          trailing: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth:
                                  40,
                            ),
                            child: PopupMenuButton<
                              String
                            >(
                              onSelected: (
                                value,
                              ) async {
                                if (value ==
                                    'delete') {
                                  _showDeleteAdvertisementConfirmation(
                                    advertisement,
                                  );
                                }
                              },
                              itemBuilder:
                                  (
                                    context,
                                  ) => [
                                    const PopupMenuItem(
                                      value:
                                          'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            color:
                                                Colors.red,
                                          ),
                                          SizedBox(
                                            width:
                                                8,
                                          ),
                                          Text(
                                            'Delete Advertisement',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  void _showDeleteReviewConfirmation(
    Review review,
  ) {
    showDialog(
      context:
          context,
      builder:
          (
            context,
          ) => AlertDialog(
            title: const Text(
              'Delete Review',
            ),
            content: Text(
              'Are you sure you want to delete this review by ${review.reviewerUsername}?',
            ),
            actions: [
              TextButton(
                onPressed:
                    () =>
                        Navigator.of(
                          context,
                        ).pop(),
                child: const Text(
                  'Cancel',
                ),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await _db.deleteReview(
                      review.id,
                      review.businessUsername,
                    );
                    if (mounted) {
                      Navigator.of(
                        context,
                      ).pop();
                      _loadReviews();
                      _loadAnalytics(); // Refresh analytics after deleting review
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Review deleted successfully',
                          ),
                          backgroundColor:
                              Colors.green,
                        ),
                      );
                    }
                  } catch (
                    e
                  ) {
                    if (mounted) {
                      Navigator.of(
                        context,
                      ).pop();
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error deleting review: $e',
                          ),
                          backgroundColor:
                              Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor:
                      Colors.red,
                ),
                child: const Text(
                  'Delete',
                ),
              ),
            ],
          ),
    );
  }

  void _showDeleteAdvertisementConfirmation(
    Map<
      String,
      dynamic
    >
    advertisement,
  ) {
    showDialog(
      context:
          context,
      builder:
          (
            context,
          ) => AlertDialog(
            title: const Text(
              'Delete Advertisement',
            ),
            content: Text(
              'Are you sure you want to delete the advertisement for ${advertisement['businessName'] ?? 'this business'}?',
            ),
            actions: [
              TextButton(
                onPressed:
                    () =>
                        Navigator.of(
                          context,
                        ).pop(),
                child: const Text(
                  'Cancel',
                ),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await _db.deleteAdvertisement(
                      advertisement['username'],
                    );
                    if (mounted) {
                      Navigator.of(
                        context,
                      ).pop();
                      _loadAdvertisements();
                      _loadAnalytics(); // Refresh analytics after deleting advertisement
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Advertisement deleted successfully',
                          ),
                          backgroundColor:
                              Colors.green,
                        ),
                      );
                    }
                  } catch (
                    e
                  ) {
                    if (mounted) {
                      Navigator.of(
                        context,
                      ).pop();
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error deleting advertisement: $e',
                          ),
                          backgroundColor:
                              Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor:
                      Colors.red,
                ),
                child: const Text(
                  'Delete',
                ),
              ),
            ],
          ),
    );
  }
}
