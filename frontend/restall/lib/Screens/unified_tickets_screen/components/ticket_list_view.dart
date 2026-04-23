import 'package:flutter/material.dart';
import 'package:restall/components/ticket_card.dart';
import 'package:restall/constants.dart';
import 'package:restall/models/TicketList.dart';

class TicketListView extends StatelessWidget {
  final Future<List<Ticket>>? future;
  final Future<List<Ticket>> Function() onRefresh;
  final GlobalKey<RefreshIndicatorState> refreshKey;
  final String noTicketsMessage;
  final String noTicketsSubtitle;
  final IconData emptyIcon;

  const TicketListView({
    Key? key,
    required this.future,
    required this.onRefresh,
    required this.refreshKey,
    required this.noTicketsMessage,
    required this.noTicketsSubtitle,
    required this.emptyIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Ticket>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: secondaryColor,
                strokeWidth: 3,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: RefreshIndicator(
              key: refreshKey,
              onRefresh: onRefresh,
              color: secondaryColor,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: constraints.maxHeight,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.error_outline_rounded,
                                size: 64,
                                color: Colors.red.shade600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Errore di connessione',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Trascina verso il basso per riprovare',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
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
          );
        }

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final tickets = snapshot.data!;
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: RefreshIndicator(
              key: refreshKey,
              onRefresh: onRefresh,
              color: secondaryColor,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: tickets.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TicketCard(ticket: tickets[index]),
                  );
                },
              ),
            ),
          );
        }

        // Empty state
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: RefreshIndicator(
            key: refreshKey,
            onRefresh: onRefresh,
            color: secondaryColor,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              emptyIcon,
                              size: 64,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            noTicketsMessage,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            noTicketsSubtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Trascina verso il basso per aggiornare',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
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
        );
      },
    );
  }
}
