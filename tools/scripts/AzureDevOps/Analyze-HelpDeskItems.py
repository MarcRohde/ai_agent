"""
Analyze Azure DevOps Help Desk work items by assignee.

This script processes Azure DevOps work item query results and calculates
metrics for Help Desk work items including average days open per assignee.

Usage:
    python Analyze-HelpDeskItems.py <json_file_path> [analysis_date]

Arguments:
    json_file_path: Path to JSON file containing Azure DevOps work item query results
    analysis_date: Optional date for analysis in YYYY-MM-DD format (defaults to today)

Example:
    python Analyze-HelpDeskItems.py results.json
    python Analyze-HelpDeskItems.py results.json 2026-03-08
"""

import json
import sys
from datetime import datetime
from collections import defaultdict
from pathlib import Path


def parse_args():
    """Parse command line arguments."""
    if len(sys.argv) < 2:
        print("Error: JSON file path required")
        print("\nUsage: python Analyze-HelpDeskItems.py <json_file_path> [analysis_date]")
        print("\nExample:")
        print("  python Analyze-HelpDeskItems.py results.json")
        print("  python Analyze-HelpDeskItems.py results.json 2026-03-08")
        sys.exit(1)

    json_path = sys.argv[1]

    # Parse analysis date if provided, otherwise use today
    if len(sys.argv) >= 3:
        try:
            analysis_date = datetime.strptime(sys.argv[2], '%Y-%m-%d')
        except ValueError:
            print(f"Error: Invalid date format '{sys.argv[2]}'. Use YYYY-MM-DD")
            sys.exit(1)
    else:
        analysis_date = datetime.now()

    return json_path, analysis_date


def load_work_items(json_path):
    """Load work items from JSON file."""
    json_file = Path(json_path)

    if not json_file.exists():
        print(f"Error: File not found: {json_path}")
        sys.exit(1)

    try:
        with open(json_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        return data
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON file: {e}")
        sys.exit(1)


def analyze_help_desk_items(data, analysis_date):
    """Analyze Help Desk work items and calculate metrics."""
    assignee_stats = defaultdict(lambda: {'total_days': 0, 'count': 0, 'items': []})

    # Process each work item - FILTER FOR HELP DESK ONLY
    for item in data['results']:
        fields = item['fields']
        work_item_type = fields['system.workitemtype']

        # Only process "Help Desk" work item types
        if work_item_type != 'Help Desk':
            continue

        work_item_id = fields['system.id']
        title = fields['system.title']
        state = fields['system.state']
        created_date_str = fields['system.createddate']

        # Parse created date (make it naive by removing timezone)
        created_date = datetime.fromisoformat(created_date_str.replace('Z', '+00:00')).replace(tzinfo=None)

        # Calculate days open
        days_open = (analysis_date - created_date).days

        # Get assignee (handle case where it might not be assigned)
        assignee = fields.get('system.assignedto', 'Unassigned')

        # Store the data
        assignee_stats[assignee]['total_days'] += days_open
        assignee_stats[assignee]['count'] += 1
        assignee_stats[assignee]['items'].append({
            'id': work_item_id,
            'type': work_item_type,
            'title': title,
            'state': state,
            'days_open': days_open,
            'created_date': created_date_str
        })

    return assignee_stats


def print_results(assignee_stats, total_items, analysis_date):
    """Print analysis results."""
    # Calculate averages and sort by average days
    results = []
    for assignee, stats in assignee_stats.items():
        avg_days = stats['total_days'] / stats['count']
        results.append({
            'assignee': assignee,
            'count': stats['count'],
            'avg_days_open': round(avg_days, 1),
            'total_days': stats['total_days']
        })

    # Sort by average days open (descending)
    results.sort(key=lambda x: x['avg_days_open'], reverse=True)

    # Calculate total help desk items processed
    total_helpdesk = sum(r['count'] for r in results)

    print('\n=== OPEN HELP DESK WORK ITEMS BY ASSIGNEE ===\n')
    print(f'Total Help Desk Items: {total_helpdesk}')
    print(f'Total Results in Query: {total_items}')
    print(f'Analysis Date: {analysis_date.strftime("%Y-%m-%d")}\n')
    print(f'{"Assignee":<50} {"Count":>6} {"Avg Days":>10} {"Total Days":>12}')
    print('=' * 80)

    for result in results:
        assignee_name = result['assignee'].split('<')[0].strip() if '<' in result['assignee'] else result['assignee']
        print(f'{assignee_name:<50} {result["count"]:>6} {result["avg_days_open"]:>10.1f} {result["total_days"]:>12}')

    print('\n=== TOP 10 LONGEST OPEN HELP DESK ITEMS ===\n')
    all_items = []
    for assignee, stats in assignee_stats.items():
        for item in stats['items']:
            all_items.append({
                'assignee': assignee,
                'id': item['id'],
                'type': item['type'],
                'title': item['title'][:60],
                'days_open': item['days_open']
            })

    all_items.sort(key=lambda x: x['days_open'], reverse=True)
    print(f'{"ID":<10} {"Type":<20} {"Days":>6} {"Assignee":<30} {"Title"}')
    print('=' * 120)
    for item in all_items[:10]:
        assignee_name = item['assignee'].split('<')[0].strip() if '<' in item['assignee'] else item['assignee']
        print(f'{item["id"]:<10} {item["type"]:<20} {item["days_open"]:>6} {assignee_name:<30} {item["title"]}')


def main():
    """Main entry point."""
    json_path, analysis_date = parse_args()

    # Load work items
    data = load_work_items(json_path)

    # Analyze Help Desk items
    assignee_stats = analyze_help_desk_items(data, analysis_date)

    # Print results
    print_results(assignee_stats, data['count'], analysis_date)


if __name__ == '__main__':
    main()
