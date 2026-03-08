import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:un_autre_regard/config/approach_config.dart';

class ApproachSelector extends StatefulWidget {
  final List<String> selectedApproaches;
  final Function(List<String>) onApproachesChanged;

  const ApproachSelector({
    super.key,
    required this.selectedApproaches,
    required this.onApproachesChanged,
  });

  @override
  State<ApproachSelector> createState() => _ApproachSelectorState();
}

class _ApproachSelectorState extends State<ApproachSelector>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late List<String> _selectedApproaches;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedApproaches = List.from(widget.selectedApproaches);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header simple
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose your perspectives',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_selectedApproaches.length} approaches selected',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        
        // TabBar simple
        TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'Spiritual'),
            Tab(text: 'Psychological'),
            Tab(text: 'Literary'),
          ],
        ),
        
        // TabBarView
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSimpleList(ApproachType.spiritual),
              _buildSimpleList(ApproachType.psychological),
              _buildSimpleList(ApproachType.literary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleList(ApproachType type) {
    final approaches = ApproachCategories.getByType(type);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: approaches.length,
      itemBuilder: (context, index) {
        final approach = approaches[index];
        final isSelected = _selectedApproaches.contains(approach.key);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              approach.icon,
              color: approach.color,
            ),
            title: Text(
              approach.name,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              approach.description,
              style: GoogleFonts.inter(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Checkbox(
              value: isSelected,
              onChanged: (_) => _toggleApproach(approach.key),
              activeColor: approach.color,
            ),
            onTap: () => _toggleApproach(approach.key),
          ),
        );
      },
    );
  }

  void _toggleApproach(String approachKey) {
    setState(() {
      if (_selectedApproaches.contains(approachKey)) {
        _selectedApproaches.remove(approachKey);
      } else {
        _selectedApproaches.add(approachKey);
      }
    });
    widget.onApproachesChanged(_selectedApproaches);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
