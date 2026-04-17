import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:restalltech/API/Tech/tech.dart';
import 'package:restalltech/API/Ticket/ticket.dart';
import 'package:restalltech/constants.dart';
import 'dart:math' as math;

class TechDetailScreen extends StatefulWidget {
  final Map<String, dynamic> tech;
  final Map<String, dynamic> stats;

  const TechDetailScreen({
    Key? key,
    required this.tech,
    this.stats = const {},
  }) : super(key: key);

  @override
  State<TechDetailScreen> createState() => _TechDetailScreenState();
}

class _TechDetailScreenState extends State<TechDetailScreen> {
  late TextEditingController _pagaController;
  late bool _isActive;
  bool _isLoadingStats = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _pagaController =
        TextEditingController(text: widget.tech['paga'].toString());
    _isActive = widget.tech['verified'].toString().toUpperCase() == 'TRUE';
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);

    try {
      final techId = widget.tech['id'];
      print('Loading analytics for tech ID: $techId');

      // Usa l'endpoint che restituisce analytics già calcolate dal backend
      final response = await TechApi().getTechbyID(techId);

      if (response.statusCode != 200) {
        throw Exception('Failed to load tech analytics: ${response.statusCode}');
      }

      final body = json.decode(response.body);
      print('Response body: $body');

      final analytics = body['analytics'];
      print('Analytics data: $analytics');

      // Mappa i dati dal formato backend al formato usato nel frontend
      final statsData = {
        'completedCount': analytics['chiusi'] ?? 0,
        'inProgressCount': analytics['incorso'] ?? 0,
        'activeCount': (analytics['incorso'] ?? 0) + (analytics['numSospesi'] ?? 0),
        'totalAssigned': (analytics['chiusi'] ?? 0) + (analytics['incorso'] ?? 0) + (analytics['numSospesi'] ?? 0),
        'todayCount': 0, // Il backend non fornisce questo dato, lo calcoliamo separatamente se necessario
      };

      print('Mapped stats: $statsData');

      setState(() {
        _stats = statsData;
        _isLoadingStats = false;
      });
    } catch (e) {
      print('Error loading stats: $e');
      setState(() {
        _stats = {
          'todayCount': 0,
          'activeCount': 0,
          'completedCount': 0,
          'inProgressCount': 0,
          'totalAssigned': 0,
        };
        _isLoadingStats = false;
      });
    }
  }

  @override
  void dispose() {
    _pagaController.dispose();
    super.dispose();
  }

  Future<void> _toggleStatus(bool newValue) async {
    try {
      var data = {"verified": newValue.toString().toUpperCase()};
      int resp = await TechApi().setStatusTech(data, widget.tech['id']);

      if (resp == 200) {
        setState(() {
          _isActive = newValue;
          widget.tech['verified'] = newValue.toString().toUpperCase();
        });
        FlutterPlatformAlert.showAlert(
          windowTitle: 'Successo',
          text: 'Stato del tecnico aggiornato',
          alertStyle: AlertButtonStyle.ok,
          iconStyle: IconStyle.information,
        );
      }
    } catch (e) {
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Errore',
        text: 'Impossibile aggiornare lo stato',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
    }
  }

  Future<void> _savePaga() async {
    final newPaga = double.tryParse(_pagaController.text);
    if (newPaga == null) {
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Errore',
        text: 'Inserisci un valore valido',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
      return;
    }

    try {
      var data = {"pagamento_orario": newPaga};
      int resp = await TechApi().setPaga(data, widget.tech['id']);
      if (resp == 200) {
        setState(() {
          widget.tech['paga'] = newPaga;
        });
        FlutterPlatformAlert.showAlert(
          windowTitle: 'Successo',
          text: 'Paga oraria aggiornata',
          alertStyle: AlertButtonStyle.ok,
          iconStyle: IconStyle.information,
        );
      }
    } catch (e) {
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Errore',
        text: 'Impossibile aggiornare la paga oraria',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
    }
  }

  Widget _buildPieChart() {
    if (_isLoadingStats) {
      return Center(child: CircularProgressIndicator());
    }

    final total = _stats['totalAssigned'] as int? ?? 0;
    final completed = _stats['completedCount'] as int? ?? 0;
    final inProgress = _stats['inProgressCount'] as int? ?? 0;
    final active = _stats['activeCount'] as int? ?? 0;

    if (total == 0) {
      return Center(
        child: Text('Nessun dato disponibile',
            style: TextStyle(color: Colors.grey[600])),
      );
    }

    return Container(
      height: 220,
      child: CustomPaint(
        painter: PieChartPainter(
          completed: completed,
          inProgress: inProgress,
          active: active,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$total',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: secondaryColor,
                ),
              ),
              Text(
                'Ticket Totali',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    if (_isLoadingStats) {
      return Center(child: CircularProgressIndicator());
    }

    final today = _stats['todayCount'] as int? ?? 0;
    final active = _stats['activeCount'] as int? ?? 0;
    final inProgress = _stats['inProgressCount'] as int? ?? 0;
    final completed = _stats['completedCount'] as int? ?? 0;

    var maxValue =
        [today, active, inProgress, completed].reduce(math.max).toDouble();
    if (maxValue == 0) maxValue = 1.0;

    return Column(
      children: [
        _buildBar('Oggi', today, Colors.blue, maxValue),
        SizedBox(height: 12),
        _buildBar('Attivi', active, Colors.orange, maxValue),
        SizedBox(height: 12),
        _buildBar('In Corso', inProgress, Colors.purple, maxValue),
        SizedBox(height: 12),
        _buildBar('Completati', completed, Colors.green, maxValue),
      ],
    );
  }

  Widget _buildBar(String label, int value, Color color, double maxValue) {
    final percentage = maxValue > 0 ? value / maxValue : 0.0;

    // Gradienti personalizzati per ogni colore
    List<Color> getGradientColors(Color baseColor) {
      if (baseColor == Colors.blue) {
        return [Color(0xFF2196F3), Color(0xFF64B5F6)];
      } else if (baseColor == Colors.orange) {
        return [Color(0xFFFF9800), Color(0xFFFFB74D)];
      } else if (baseColor == Colors.purple) {
        return [Color(0xFF9C27B0), Color(0xFFAB47BC)];
      } else if (baseColor == Colors.green) {
        return [Color(0xFF4CAF50), Color(0xFF66BB6A)];
      }
      return [baseColor, baseColor.withValues(alpha: 0.7)];
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 75,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    AnimatedContainer(
                      duration: Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      height: 32,
                      width: percentage *
                          (MediaQuery.of(context).size.width - 180),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: getGradientColors(color),
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Container(
            width: 36,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: getGradientColors(color),
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$value',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int value) {
    // Gradienti personalizzati
    List<Color> getGradientColors(Color baseColor) {
      if (baseColor == Colors.green) {
        return [Color(0xFF4CAF50), Color(0xFF66BB6A)];
      } else if (baseColor == Colors.purple) {
        return [Color(0xFF9C27B0), Color(0xFFAB47BC)];
      } else if (baseColor == Colors.orange) {
        return [Color(0xFFFF9800), Color(0xFFFFB74D)];
      }
      return [baseColor, baseColor.withValues(alpha: 0.7)];
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: getGradientColors(color),
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
          ),
          Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: getGradientColors(color),
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '$value',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Dettagli Tecnico'),
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Ricarica statistiche',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Card
            Container(
              width: double.infinity,
              color: secondaryColor,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 40,
                      child: Text(
                        '${widget.tech['nome'][0]}${widget.tech['cognome'][0]}',
                        style: TextStyle(
                          color: secondaryColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '${widget.tech['cognome']} ${widget.tech['nome']}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isActive ? Colors.green : Colors.grey[600],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isActive ? Icons.check_circle : Icons.cancel,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            _isActive ? 'Attivo' : 'Non Attivo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),

            // Statistiche - Grafico a Torta
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!, width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: secondaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.pie_chart_outline,
                              color: secondaryColor, size: 20),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Distribuzione Ticket',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    _buildPieChart(),
                    SizedBox(height: 20),
                    _buildLegendItem('Completati', Colors.green,
                        _stats['completedCount'] as int? ?? 0),
                    _buildLegendItem('In Corso', Colors.purple,
                        _stats['inProgressCount'] as int? ?? 0),
                    _buildLegendItem('Attivi', Colors.orange,
                        _stats['activeCount'] as int? ?? 0),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Statistiche - Grafico a Barre
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!, width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: secondaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.bar_chart,
                              color: secondaryColor, size: 20),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Panoramica Attività',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    _buildBarChart(),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),

            // Stato Tecnico
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!, width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.toggle_on_outlined,
                            color: secondaryColor, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Stato Tecnico',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _isActive ? 'Tecnico Attivo' : 'Tecnico Non Attivo',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        _isActive
                            ? 'Il tecnico può ricevere assegnazioni'
                            : 'Il tecnico non riceverà nuove assegnazioni',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      value: _isActive,
                      activeTrackColor: Colors.green[200],
                      activeThumbColor: Colors.green,
                      onChanged: (newValue) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            title: Row(
                              children: [
                                Icon(
                                  newValue ? Icons.check_circle : Icons.cancel,
                                  color:
                                      newValue ? Colors.green : Colors.orange,
                                ),
                                SizedBox(width: 8),
                                Text('Conferma'),
                              ],
                            ),
                            content: Text(
                              newValue
                                  ? 'Sei sicuro di voler attivare ${widget.tech['cognome']} ${widget.tech['nome']}?'
                                  : 'Sei sicuro di voler disattivare ${widget.tech['cognome']} ${widget.tech['nome']}?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text('Annulla',
                                    style: TextStyle(color: Colors.grey[600])),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _toggleStatus(newValue);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      newValue ? Colors.green : Colors.orange,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(newValue ? 'Attiva' : 'Disattiva'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),

            // Paga Oraria
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!, width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: secondaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.euro_outlined,
                              color: secondaryColor, size: 20),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Paga Oraria',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _pagaController,
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          textInputAction: TextInputAction.done,
                          cursorColor: kPrimaryColor,
                          decoration: InputDecoration(
                            hintText: 'Paga oraria (€/h)',
                            prefixIcon: Padding(
                              padding: EdgeInsets.all(defaultPadding),
                              child: Icon(Icons.euro_rounded),
                            ),
                          ),
                        ),
                        SizedBox(height: defaultPadding),
                        ElevatedButton.icon(
                          onPressed: _savePaga,
                          icon: Icon(Icons.save_rounded),
                          label: Text('Salva'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// Custom Painter per il grafico a torta
class PieChartPainter extends CustomPainter {
  final int completed;
  final int inProgress;
  final int active;

  PieChartPainter({
    required this.completed,
    required this.inProgress,
    required this.active,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = completed + inProgress + active;
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.5;

    double startAngle = -math.pi / 2;

    // Ombra esterna per tutto il cerchio
    final outerShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius, outerShadowPaint);

    // Completati (verde con gradiente)
    if (completed > 0) {
      final sweepAngle = (completed / total) * 2 * math.pi;

      final rect = Rect.fromCircle(center: center, radius: radius);
      final gradient = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [
          Color(0xFF4CAF50),
          Color(0xFF66BB6A),
        ],
      );

      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      startAngle += sweepAngle;
    }

    // In Corso (viola con gradiente)
    if (inProgress > 0) {
      final sweepAngle = (inProgress / total) * 2 * math.pi;

      final rect = Rect.fromCircle(center: center, radius: radius);
      final gradient = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [
          Color(0xFF9C27B0),
          Color(0xFFAB47BC),
        ],
      );

      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      startAngle += sweepAngle;
    }

    // Attivi (arancione con gradiente)
    if (active > 0) {
      final sweepAngle = (active / total) * 2 * math.pi;

      final rect = Rect.fromCircle(center: center, radius: radius);
      final gradient = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [
          Color(0xFFFF9800),
          Color(0xFFFFB74D),
        ],
      );

      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
    }

    // Cerchio interno bianco per effetto ciambella con ombra
    final innerShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.06)
      ..maskFilter = MaskFilter.blur(BlurStyle.inner, 6);
    canvas.drawCircle(center, radius * 0.58, innerShadowPaint);

    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.6, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
