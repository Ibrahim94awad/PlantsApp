import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../theme.dart';

class InventoryCard extends StatefulWidget {
  const InventoryCard({
    super.key,
    required this.row,
    required this.distributions,
    required this.onEdit,
    required this.onCopy,
    required this.onDelete,
    required this.onHistory,
    required this.onDistribute,
    required this.onEditDistribution,
  });

  final InventoryRow row;
  final List<DistributionRow> distributions;
  final VoidCallback onEdit;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final VoidCallback onHistory;
  final VoidCallback onDistribute;
  final ValueChanged<DistributionRow> onEditDistribution;

  @override
  State<InventoryCard> createState() => _InventoryCardState();
}

class _InventoryCardState extends State<InventoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final distributions = widget.distributions;
    final total =
        row.quantity + distributions.fold<int>(0, (sum, d) => sum + d.quantity);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderRow(
                      row: row,
                      hasDistributions: distributions.isNotEmpty,
                      expanded: _expanded),
                  const SizedBox(height: 6),
                  _LocationRow(row: row),
                  const SizedBox(height: 4),
                  Text('Maat: ${row.size}',
                      style: const TextStyle(
                          color: kOnSurfaceVariant, fontSize: 14)),
                  if (!_expanded) ...[
                    const SizedBox(height: 6),
                    _CollapsedSummary(
                        row: row,
                        hasDistributions: distributions.isNotEmpty,
                        total: total),
                  ],
                ],
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              _OriginalPanel(
                  row: row, hasDistributions: distributions.isNotEmpty),
              if (distributions.isNotEmpty) ...[
                for (final distribution in distributions) ...[
                  const SizedBox(height: 8),
                  _DistributionTile(
                      distribution: distribution,
                      onTap: () => widget.onEditDistribution(distribution)),
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Totaal: ${formatQuantity(total)}',
                    style: const TextStyle(
                        color: kPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              _CardActions(
                onDistribute: widget.onDistribute,
                onEdit: widget.onEdit,
                onCopy: widget.onCopy,
                onHistory: widget.onHistory,
                onDelete: widget.onDelete,
              ),
            ],
            const SizedBox(height: 8),
            _CreatedFooter(createdAt: row.createdAt),
          ],
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow(
      {required this.row,
      required this.hasDistributions,
      required this.expanded});
  final InventoryRow row;
  final bool hasDistributions;
  final bool expanded;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              row.plant,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16, color: kOnSurface),
            ),
          ),
          const SizedBox(width: 8),
          if (hasDistributions) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: kStatusBg, borderRadius: BorderRadius.circular(6)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.call_split, size: 14, color: kPrimaryDark),
                  SizedBox(width: 4),
                  Text('Verdeeld',
                      style: TextStyle(
                          color: kPrimaryDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: kStatusGreen, borderRadius: BorderRadius.circular(6)),
            child: Text(
              'Nr. ${row.sequenceNumber ?? row.id}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12),
            ),
          ),
          const SizedBox(width: 4),
          Icon(expanded ? Icons.expand_less : Icons.expand_more,
              color: kOnSurfaceVariant),
        ],
      );
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.row});
  final InventoryRow row;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Icon(Icons.location_on_outlined,
              size: 16, color: kOnSurfaceVariant),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '${row.department} › ${row.subDepartment}',
              style: const TextStyle(color: kOnSurfaceVariant, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
}

class _CollapsedSummary extends StatelessWidget {
  const _CollapsedSummary(
      {required this.row, required this.hasDistributions, required this.total});
  final InventoryRow row;
  final bool hasDistributions;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (hasDistributions) {
      return Align(
        alignment: Alignment.centerRight,
        child: Text('Totaal: ${formatQuantity(total)}',
            style: const TextStyle(
                color: kPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
      );
    }
    return Row(
      children: [
        Expanded(
            child: Text('Lijn ${row.line}',
                style: const TextStyle(
                    color: kOnSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14))),
        Text('Aantal ${formatQuantity(row.quantity)}',
            style: const TextStyle(
                color: kPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
      ],
    );
  }
}

class _OriginalPanel extends StatelessWidget {
  const _OriginalPanel({required this.row, required this.hasDistributions});
  final InventoryRow row;
  final bool hasDistributions;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: kPanelTint,
          borderRadius: BorderRadius.circular(8),
          border: hasDistributions
              ? const Border(left: BorderSide(color: kPrimary, width: 4))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasDistributions) ...[
              const Text('Origineel',
                  style: TextStyle(
                      color: kPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
              const SizedBox(height: 6),
            ],
            Row(
              children: [
                _CardMetric(label: 'Lijn', value: row.line),
                _CardMetric(
                    label: 'Aantal',
                    value: formatQuantity(row.quantity),
                    highlight: true),
                const Spacer(),
              ],
            ),
          ],
        ),
      );
}

class _DistributionTile extends StatelessWidget {
  const _DistributionTile({required this.distribution, required this.onTap});
  final DistributionRow distribution;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
              color: kPanelTint, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              _CardMetric(label: 'Lijn', value: distribution.line),
              _CardMetric(
                  label: 'Aantal',
                  value: formatQuantity(distribution.quantity),
                  highlight: true),
              const Expanded(
                  child: Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.edit_outlined,
                          size: 18, color: kOnSurfaceVariant))),
            ],
          ),
        ),
      );
}

class _CardActions extends StatelessWidget {
  const _CardActions({
    required this.onDistribute,
    required this.onEdit,
    required this.onCopy,
    required this.onHistory,
    required this.onDelete,
  });
  final VoidCallback onDistribute;
  final VoidCallback onEdit;
  final VoidCallback onCopy;
  final VoidCallback onHistory;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
              onPressed: onDistribute,
              icon: const Icon(Icons.call_split, color: kPrimary),
              tooltip: 'Verdelen'),
          IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, color: kOnSurfaceVariant),
              tooltip: 'Bewerken'),
          IconButton(
              onPressed: onCopy,
              icon: const Icon(Icons.copy_outlined, color: kOnSurfaceVariant),
              tooltip: 'Kopiëren'),
          IconButton(
              onPressed: onHistory,
              icon: const Icon(Icons.history, color: kOnSurfaceVariant),
              tooltip: 'Geschiedenis'),
          IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: kDanger),
              tooltip: 'Verwijderen'),
        ],
      );
}

class _CreatedFooter extends StatelessWidget {
  const _CreatedFooter({required this.createdAt});
  final int createdAt;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Text('Aangemaakt op:',
              style: TextStyle(color: kOnSurfaceVariant, fontSize: 14)),
          const SizedBox(width: 4),
          Text(formatDateTime(createdAt),
              style: const TextStyle(color: kOnSurfaceVariant, fontSize: 14)),
        ],
      );
}

class _CardMetric extends StatelessWidget {
  const _CardMetric(
      {required this.label, required this.value, this.highlight = false});
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: kOnSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: highlight ? kPrimary : kOnSurface,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
}
