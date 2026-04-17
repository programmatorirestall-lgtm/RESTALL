import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:graphview/GraphView.dart';
import 'package:http/http.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:restall/API/User/user.dart';
import 'package:restall/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReferralNetworkScreen extends StatefulWidget {
  @override
  _ReferralNetworkScreenState createState() => _ReferralNetworkScreenState();
}

class _ReferralNetworkScreenState extends State<ReferralNetworkScreen>
    with TickerProviderStateMixin {
  final Graph graph = Graph()..isTree = true;
  final BuchheimWalkerConfiguration builder = BuchheimWalkerConfiguration();
  Map<int, Node> nodesById = {};
  List<Map<String, dynamic>> network = [];
  bool isListView = false;
  bool isLoading = false;
  String? errorMessage;

  int? selectedLevel;
  String searchQuery = '';

  late AnimationController _pulseController;
  late AnimationController _progressController;
  late AnimationController _sparkleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _sparkleAnimation;

  // Statistiche
  int get totalMembers => network.length;
  int get directReferrals => network.where((e) => e['level'] == 1).length;
  int get indirectReferrals => network.where((e) => e['level'] > 1).length;
  int get maxLevel => network.isEmpty
      ? 0
      : network.map((e) => e['level'] as int).reduce((a, b) => a > b ? a : b);

  // Mock dati crescita ultimi 7 e 30 giorni (in reale: da API)
  final List<int> growthLast7Days = [1, 2, 3, 2, 4, 2, 5];
  final List<int> growthLast30Days = [
    1,
    2,
    3,
    2,
    1,
    0,
    2,
    3,
    2,
    1,
    0,
    2,
    4,
    2,
    5,
    3,
    2,
    1,
    0,
    2,
    3,
    2,
    1,
    2,
    1,
    3,
    2,
    1,
    0,
    2
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    fetchNetwork();
    //_checkAchievements();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _progressController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _sparkleController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.elasticOut),
    );

    _sparkleAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.linear),
    );
  }

  void _checkAchievements() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      // Check first referral achievement
      if (directReferrals >= 1) {
        var achievement =
            achievements.firstWhere((a) => a['id'] == 'first_referral');
        bool alreadyShown =
            prefs.getBool('achievement_${achievement['id']}') ?? false;
        if (!achievement['unlocked']) {
          achievement['unlocked'] = true;
          if (!alreadyShown) {
            _showAchievementUnlocked(achievement);
            prefs.setBool('achievement_${achievement['id']}', true);
          }
        }
      }

      // Check network architect achievement
      if (maxLevel >= 3) {
        var achievement =
            achievements.firstWhere((a) => a['id'] == 'network_architect');
        bool alreadyShown =
            prefs.getBool('achievement_${achievement['id']}') ?? false;
        if (!achievement['unlocked']) {
          achievement['unlocked'] = true;
          if (!alreadyShown) {
            _showAchievementUnlocked(achievement);
            prefs.setBool('achievement_${achievement['id']}', true);
          }
        }
      }

      // Check social butterfly achievement
      if (totalMembers >= 20) {
        var achievement =
            achievements.firstWhere((a) => a['id'] == 'social_butterfly');
        bool alreadyShown =
            prefs.getBool('achievement_${achievement['id']}') ?? false;
        if (!achievement['unlocked']) {
          achievement['unlocked'] = true;
          if (!alreadyShown) {
            _showAchievementUnlocked(achievement);
            prefs.setBool('achievement_${achievement['id']}', true);
          }
        }
      }
    });
  }

  void _showAchievementUnlocked(Map<String, dynamic> achievement) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.yellow.shade600, kPrimaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Text(
                    achievement['icon'],
                    style: TextStyle(fontSize: 60),
                  ),
                ),
              ),
              SizedBox(height: 1),
              Text(
                'ACHIEVEMENT SBLOCCATO!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                achievement['title'],
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                achievement['description'],
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+${achievement['points']} punti',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Fantastico!', style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(
                backgroundColor: kPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getCurrentBadge() {
    return badges.lastWhere(
      (badge) => directReferrals >= badge['min'],
      orElse: () => badges.first,
    );
  }

  Map<String, dynamic>? _getNextBadge() {
    try {
      return badges.firstWhere((badge) => directReferrals < badge['min']);
    } catch (e) {
      return null;
    }
  }

  void fetchNetwork() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      Response response = await UserApi().getNetwork();
      if (response.statusCode == 200) {
        var body = await json.decode(response.body);
        print(body);
        setState(() {
          network = List<Map<String, dynamic>>.from(body['network']);

          buildGraph();
          isLoading = false;
        });
        _progressController.forward(); // AGGIUNGI QUESTA LINEA
        _checkAchievements(); // AGGIUNGI QUESTA LINEA
      }
    } on Exception catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Errore di connessione';
      });
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Si è verificato un errore',
        text:
            'Connessione al server non riuscita, controlla la connessione ad Internet.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  void buildGraph() {
    graph.nodes.clear();
    graph.edges.clear();
    nodesById.clear();

    // Crea tutti i nodi
    for (var person in network) {
      int id = int.parse(person['id'].toString());
      Node node = Node(_buildNodeWidget(person));
      nodesById[id] = node;
      graph.addNode(node);
    }

    // Trova "me" (level == 0)
    var me = network.firstWhere((e) => e['level'] == 0,
        orElse: () => <String, dynamic>{});
    if (me.isEmpty) return; // Nessun nodo principale -> esci

    var meId = int.parse(me['id'].toString());

    // Collega il padre se presente (level == -1)
    var padre = network.firstWhere((e) => e['level'] == -1,
        orElse: () => <String, dynamic>{});
    int? padreId;
    if (padre.isNotEmpty) {
      padreId = int.parse(padre['id'].toString());
      if (nodesById.containsKey(padreId)) {
        graph.addEdge(nodesById[padreId]!, nodesById[meId]!);
      }
    }

    // Collega i figli se presenti (level > 0)
    var figli = network.where((e) => e['level'] > 0);
    for (var figlio in figli) {
      int figlioId = int.parse(figlio['id'].toString());
      if (nodesById.containsKey(figlioId)) {
        graph.addEdge(nodesById[meId]!, nodesById[figlioId]!);
      }
    }

    builder
      ..siblingSeparation = (20)
      ..levelSeparation = (30)
      ..subtreeSeparation = (30)
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;
  }

  Widget _buildNodeWidget(Map<String, dynamic> user) {
    final level = user['level'];
    final color = level == -1
        ? Colors.red
        : level == 0
            ? Colors.blue
            : Colors.green;

    return GestureDetector(
      onTap: () => _showUserDetails(user),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() {}),
        onExit: (_) => setState(() {}),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 150),
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${user['nome']} ${user['cognome']}',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(_getLevelName(user['level']),
                  style: TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(Map<String, dynamic> user) {
    final level = user['level'];
    final color = level == -1
        ? Colors.red
        : level == 0
            ? Colors.blue
            : Colors.green;

    String levelDescription = _getLevelName(level);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(
            '${user['nome'][0]}${user['cognome'][0]}',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text('${user['nome']} ${user['cognome']}'),
        subtitle: Text(levelDescription),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Text(
            levelDescription,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        onTap: () => _showUserDetails(user),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) => Transform.scale(
        scale: 0.8 + (_progressAnimation.value * 0.2),
        child: Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.yellow.shade600, kPrimaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kPrimaryLightColor,
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                '🏆 La Tua Rete',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAnimatedStatItem(
                      'Totale\nMembri', totalMembers.toString(), '👥'),
                  _buildAnimatedStatItem(
                      'Referral\nDiretti', directReferrals.toString(), '🎯'),
                  _buildAnimatedStatItem('Referral\nIndiretti',
                      indirectReferrals.toString(), '🌐'),
                  _buildAnimatedStatItem(
                      'Profondità\nRete', maxLevel.toString(), '📊'),
                ],
              ),
              SizedBox(height: 20),
              _buildProgressToNextLevel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedStatItem(String label, String value, String emoji) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: TextStyle(fontSize: 24)),
          SizedBox(height: 4),
          Transform.scale(
            scale: _pulseAnimation.value * 0.1 + 0.9,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressToNextLevel() {
    final currentBadge = _getCurrentBadge();
    final nextBadge = _getNextBadge();

    if (nextBadge == null) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '🎉 Hai raggiunto il livello massimo!',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    }

    // CALCOLO CORRETTO: semplice rapporto tra referral attuali e target
    final progress = directReferrals / (nextBadge['min'] as int);
    final needed = (nextBadge['min'] as int) - directReferrals;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Prossimo: ${nextBadge['label']}',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Text(
              '$needed referral mancanti',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        SizedBox(height: 8),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) => ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (progress * _progressAnimation.value)
                  .clamp(0.0, 1.0), // Assicura che non superi 1.0
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 8,
            ),
          ),
        ),
      ],
    );
  }

  String getBadgeTitle(int directCount) {
    if (directCount >= 10) return 'Ambasciatore';
    if (directCount >= 6) return 'Leader';
    if (directCount >= 3) return 'Influencer';
    if (directCount >= 1) return 'Promotore';
    return 'Novizio';
  }

  Color getBadgeColor(int directCount) {
    if (directCount >= 10) return Colors.amber[700]!;
    if (directCount >= 6) return Colors.orange;
    if (directCount >= 3) return Colors.purple;
    if (directCount >= 1) return Colors.blue;
    return Colors.green;
  }

  final List<Map<String, dynamic>> badges = [
    {
      'min': 0,
      'max': 0,
      'label': 'Novizio',
      'icon': '🌱',
      'color': Colors.green,
      'description': 'Benvenuto nel mondo dei referral!',
      'reward': '5 punti bonus'
    },
    {
      'min': 1,
      'max': 2,
      'label': 'Promotore',
      'icon': '🚀',
      'color': Colors.blue,
      'description': 'Hai iniziato a costruire la tua rete!',
      'reward': '10 punti bonus + Badge Esclusivo'
    },
    {
      'min': 3,
      'max': 5,
      'label': 'Influencer',
      'icon': '🎯',
      'color': Colors.purple,
      'description': 'La tua influenza sta crescendo!',
      'reward': '25 punti bonus + Sconto 5%'
    },
    {
      'min': 6,
      'max': 9,
      'label': 'Leader',
      'icon': '👑',
      'color': Colors.orange,
      'description': 'Sei un vero leader della community!',
      'reward': '50 punti bonus + Sconto 10%'
    },
    {
      'min': 10,
      'max': 19,
      'label': 'Ambasciatore',
      'icon': '⭐',
      'color': Colors.amber,
      'description': 'Ambasciatore ufficiale del brand!',
      'reward': '100 punti bonus + Sconto 15%'
    },
    {
      'min': 20,
      'max': 49,
      'label': 'Maestro',
      'icon': '🏆',
      'color': Colors.deepOrange,
      'description': 'Maestro indiscusso dei referral!',
      'reward': '200 punti bonus + Sconto 20%'
    },
    {
      'min': 50,
      'max': 999,
      'label': 'Leggenda',
      'icon': '💎',
      'color': Colors.indigo,
      'description': 'Una vera leggenda vivente!',
      'reward': '500 punti bonus + Vantaggi VIP'
    },
  ];

  // AGGIUNGI SISTEMA ACHIEVEMENT
  List<Map<String, dynamic>> achievements = [
    {
      'id': 'first_referral',
      'title': 'Primo Passo',
      'description': 'Ottieni il tuo primo referral',
      'icon': '🎉',
      'unlocked': false,
      'points': 10
    },
    {
      'id': 'speed_builder',
      'title': 'Costruttore Veloce',
      'description': '5 referral in una settimana',
      'icon': '⚡',
      'unlocked': false,
      'points': 25
    },
    {
      'id': 'network_architect',
      'title': 'Architetto della Rete',
      'description': 'Raggiungi 3 livelli di profondità',
      'icon': '🏗️',
      'unlocked': false,
      'points': 50
    },
    {
      'id': 'social_butterfly',
      'title': 'Farfalla Sociale',
      'description': '20 referral totali',
      'icon': '🦋',
      'unlocked': false,
      'points': 75
    },
  ];

  Widget _buildUserBadgeSection() {
    final me = network.firstWhere((e) => e['level'] == 0, orElse: () => {});
    if (me.isEmpty) return SizedBox.shrink();

    final currentBadge = _getCurrentBadge();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [currentBadge['color'].withOpacity(0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: currentBadge['color'].withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _pulseAnimation.value * 0.1 + 0.9,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: currentBadge['color'],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: currentBadge['color'].withOpacity(0.4),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      currentBadge['icon'],
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentBadge['label'],
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: currentBadge['color'],
                      ),
                    ),
                    Text(
                      currentBadge['description'],
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    // Container(
                    //   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    //   decoration: BoxDecoration(
                    //     color: currentBadge['color'].withOpacity(0.1),
                    //     borderRadius: BorderRadius.circular(12),
                    //   ),
                    //   child: Text(
                    //     currentBadge['reward'],
                    //     style: TextStyle(
                    //       color: currentBadge['color'],
                    //       fontWeight: FontWeight.bold,
                    //       fontSize: 12,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                'Tutti i Badge',
                Icons.emoji_events,
                currentBadge['color'],
                () => _showAllLevelsAlert(context, directReferrals),
              ),
              // _buildActionButton(
              //   'Achievement',
              //   Icons.military_tech,
              //   Colors.purple,
              //   () => _showAchievements(),
              // ),
              // _buildActionButton(
              //   'Condividi',
              //   Icons.share,
              //   Colors.blue,
              //   () => _shareProgress(),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 7. AGGIUNGI QUESTI METODI
  void _showAchievements() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.yellow.shade600, kPrimaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Text(
                    '🏆 Achievement',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  Text(
                    '${achievements.where((a) => a['unlocked']).length}/${achievements.length}',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final achievement = achievements[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: achievement['unlocked']
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: achievement['unlocked']
                            ? Colors.green
                            : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          achievement['icon'],
                          style: TextStyle(
                            fontSize: 40,
                            color: achievement['unlocked']
                                ? null
                                : Colors.grey.withOpacity(0.5),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                achievement['title'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: achievement['unlocked']
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                              Text(
                                achievement['description'],
                                style: TextStyle(
                                  color: achievement['unlocked']
                                      ? Colors.grey[600]
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (achievement['unlocked'])
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '+${achievement['points']}',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          )
                        else
                          Icon(Icons.lock, color: Colors.grey),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareProgress() {
    final currentBadge = _getCurrentBadge();
    // Implementa logica di condivisione
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Condividi: Sono ${currentBadge['label']} con $directReferrals referral diretti! 🎉'),
        backgroundColor: currentBadge['color'],
      ),
    );
  }

  void _showAllLevelsAlert(BuildContext context, int directCount) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimaryColor.withOpacity(0.8), kPrimaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Tutti i Livelli e Badge',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  Text(
                    '${badges.where((b) => directCount >= b['min']).length}/${badges.length}',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: badges.length,
                itemBuilder: (context, index) {
                  final badge = badges[index];
                  final unlocked = directCount >= (badge['min'] as int);
                  final isActive = directCount >= (badge['min'] as int) &&
                      directCount <= (badge['max'] as int);

                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: unlocked
                          ? (isActive
                              ? badge['color'].withOpacity(0.15)
                              : Colors.green.withOpacity(0.1))
                          : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: unlocked
                            ? (isActive ? badge['color'] : Colors.green)
                            : Colors.grey.withOpacity(0.3),
                        width: isActive ? 2 : 1,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: badge['color'].withOpacity(0.2),
                                blurRadius: 8,
                                offset: Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: unlocked
                                ? badge['color'].withOpacity(0.2)
                                : Colors.grey.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            badge['icon'],
                            style: TextStyle(
                              fontSize: 32,
                              color: unlocked
                                  ? null
                                  : Colors.grey.withOpacity(0.5),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    badge['label'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          unlocked ? Colors.black : Colors.grey,
                                    ),
                                  ),
                                  if (isActive) ...[
                                    SizedBox(width: 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: badge['color'],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'ATTUALE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                badge['description'],
                                style: TextStyle(
                                  color:
                                      unlocked ? Colors.grey[600] : Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 8),
                              // Container(
                              //   padding: EdgeInsets.symmetric(
                              //       horizontal: 10, vertical: 6),
                              //   decoration: BoxDecoration(
                              //     color: unlocked
                              //         ? badge['color'].withOpacity(0.1)
                              //         : Colors.grey.withOpacity(0.1),
                              //     borderRadius: BorderRadius.circular(12),
                              //     border: Border.all(
                              //       color: unlocked
                              //           ? badge['color'].withOpacity(0.3)
                              //           : Colors.grey.withOpacity(0.3),
                              //     ),
                              //   ),
                              //   child: Text(
                              //     badge['reward'],
                              //     style: TextStyle(
                              //       color:
                              //           unlocked ? badge['color'] : Colors.grey,
                              //       fontWeight: FontWeight.bold,
                              //       fontSize: 12,
                              //     ),
                              //   ),
                              // ),
                              if (!unlocked) ...[
                                SizedBox(height: 8),
                                Text(
                                  '${badge['min'] == 1 ? 'Serve' : 'Servono'} ${badge['min']} referral dirett${badge['min'] == 1 ? 'o' : 'i'}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Icon(
                              unlocked ? Icons.check_circle : Icons.lock,
                              color: unlocked
                                  ? (isActive ? badge['color'] : Colors.green)
                                  : Colors.grey,
                              size: 24,
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${badge['min']}-${badge['max'] == 999 ? '∞' : badge['max']}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Chiudi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthChart() {
    // Semplice grafico a barre per ultimi 7 giorni
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        maxY: (growthLast7Days.reduce((a, b) => a > b ? a : b)).toDouble() + 1,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final day = value.toInt();
                if (day < 0 || day >= growthLast7Days.length)
                  return Container();
                return Text(
                    ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'][day],
                    style: TextStyle(fontSize: 8));
              },
              reservedSize: 18,
            ),
          ),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: false),
        barGroups: List.generate(
          growthLast7Days.length,
          (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: growthLast7Days[i].toDouble(),
                color: Colors.green[400],
                width: 10,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    final sortedNetwork = network.where((user) {
      final matchesLevel =
          selectedLevel == null || user['level'] == selectedLevel;
      final fullName = '${user['nome']} ${user['cognome']}'.toLowerCase();
      final matchesSearch = fullName.contains(searchQuery);
      return matchesLevel && matchesSearch;
    }).toList()
      ..sort((a, b) => a['level'].compareTo(b['level']));

// OPZIONE 1: Soluzione semplice (per liste non troppo lunghe)
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildStatisticsCard(),
          _buildUserBadgeSection(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: InputDecoration(
                    fillColor: kPrimaryLightColor,
                    hintText: 'Cerca per nome...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() => searchQuery = value.toLowerCase());
                  },
                ),
                SizedBox(height: 8),
                DropdownButton<int?>(
                  value: selectedLevel,
                  hint: Text('Filtra per livello'),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(value: null, child: Text('Tutti')),
                    ...List.generate(
                      maxLevel + 1,
                      (index) => DropdownMenuItem(
                        value: index,
                        child: Text('Livello $index'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => selectedLevel = value);
                  },
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
          ...sortedNetwork.map((item) => _buildListItem(item)).toList(),
          SizedBox(height: 100), // Spazio per il FAB
        ],
      ),
    );

// OPZIONE 2: Soluzione ottimizzata (per liste lunghe)
/*
return CustomScrollView(
  slivers: [
    SliverToBoxAdapter(
      child: Column(
        children: [
          _buildStatisticsCard(),
          _buildUserBadgeSection(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: InputDecoration(
                    fillColor: Colors.white,
                    hintText: 'Cerca per nome...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() => searchQuery = value.toLowerCase());
                  },
                ),
                SizedBox(height: 8),
                DropdownButton<int?>(
                  value: selectedLevel,
                  hint: Text('Filtra per livello'),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(value: null, child: Text('Tutti')),
                    ...List.generate(
                      maxLevel + 1,
                      (index) => DropdownMenuItem(
                        value: index,
                        child: Text('Livello $index'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => selectedLevel = value);
                  },
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    ),
    SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildListItem(sortedNetwork[index]),
        childCount: sortedNetwork.length,
      ),
    ),
    SliverToBoxAdapter(
      child: SizedBox(height: 100), // Spazio per il FAB
    ),
  ],
);
*/
  }

  Widget _buildGraphView() {
    return Column(
      children: [
        _buildStatisticsCard(),
        Expanded(
          child: InteractiveViewer(
            constrained: false,
            boundaryMargin: EdgeInsets.all(100),
            minScale: 0.01,
            maxScale: 5.0,
            child: GraphView(
              graph: graph,
              algorithm:
                  BuchheimWalkerAlgorithm(builder, TreeEdgeRenderer(builder)),
              builder: (Node node) {
                return _buildNodeWidget(node.key!.value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          SizedBox(height: 16),
          Text(
            errorMessage ?? "Errore sconosciuto",
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: fetchNetwork,
            child: Text('Riprova'),
          ),
        ],
      ),
    );
  }

  void _showModeSelector() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Seleziona Vista',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.list,
                  color: isListView ? Colors.blue : Colors.grey),
              title: Text('Vista Lista'),
              trailing:
                  isListView ? Icon(Icons.check, color: Colors.blue) : null,
              onTap: () {
                setState(() {
                  isListView = true;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.account_tree,
                  color: !isListView ? Colors.blue : Colors.grey),
              title: Text('Vista Grafo'),
              trailing:
                  !isListView ? Icon(Icons.check, color: Colors.blue) : null,
              onTap: () {
                setState(() {
                  isListView = false;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Caricamento rete referral...'),
                ],
              ),
            )
          : errorMessage != null
              ? _buildErrorWidget()
              : network.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Nessun referral trovato'),
                        ],
                      ),
                    )
                  : isListView
                      ? _buildListView()
                      : _buildGraphView(),
      floatingActionButton: network.isNotEmpty && errorMessage == null
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    heroTag: 'Ricarica',
                    onPressed: isLoading ? null : fetchNetwork,
                    tooltip: 'Ricarica',
                    backgroundColor: primaryColor,
                    child: isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(Icons.refresh),
                    mini: true,
                  ),
                  FloatingActionButton(
                    heroTag: 'Vista',
                    onPressed: _showModeSelector,
                    backgroundColor: primaryColor,
                    tooltip: isListView ? 'Grafo' : 'Lista',
                    child: Icon(isListView ? Icons.account_tree : Icons.list),
                    mini: true,
                  ),
                ],
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Text('${user['nome'][0]}${user['cognome'][0]}'),
              ),
              title: Text('${user['nome']} ${user['cognome']}',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Ruolo: ${_getLevelName(user['level'])}'),
            ),
            if (user['email'] != null)
              Padding(
                padding: EdgeInsets.only(left: 16, top: 4),
                child: Text('Email: ${user['email']}'),
              ),
            if (user['data_iscrizione'] != null)
              Padding(
                padding: EdgeInsets.only(left: 16, top: 4),
                child: Text('Iscritto il: ${user['data_iscrizione']}'),
              ),
            if (user['premi'] != null)
              Padding(
                padding: EdgeInsets.only(left: 16, top: 4),
                child: Text('Premi: ${user['premi']}'),
              ),
            if (user['id'] != null)
              Padding(
                padding: EdgeInsets.only(left: 16, top: 4),
                child: Text('ID: ${user['id']}',
                    style: TextStyle(color: Colors.grey[600])),
              ),
          ],
        ),
      ),
    );
  }

  String _getLevelName(dynamic level) {
    if (level == -1) return 'Sponsor';
    if (level == 0) return 'Me';
    if (level == 1) return 'Diretto';
    return 'Liv. $level';
  }
}
