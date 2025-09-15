import json
import boto3
import os
import urllib3
from datetime import datetime, timedelta
from decimal import Decimal

def lambda_handler(event, context):
    """
    Lambda function to retrieve AWS billing information and send via webhook
    """
    try:
        # Get environment variables
        webhook_url = os.environ['WEBHOOK_URL']

        # Initialize AWS Cost Explorer client
        ce_client = boto3.client('ce', region_name='us-east-1')  # Cost Explorer is only available in us-east-1

        # Get billing data
        billing_data = get_billing_data(ce_client)

        # Format and send webhook notification
        send_webhook_notification(webhook_url, billing_data)

        return {
            'statusCode': 200,
            'body': json.dumps('Billing alert sent successfully')
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error: {str(e)}')
        }

def get_billing_data(ce_client):
    """
    Retrieve billing data from AWS Cost Explorer
    """
    # Get current date and calculate date range
    end_date = datetime.now().date()
    start_date = end_date.replace(day=1)  # First day of current month

    # Format dates for API
    start_str = start_date.strftime('%Y-%m-%d')
    end_str = end_date.strftime('%Y-%m-%d')

    # Get total cost for the month
    total_response = ce_client.get_cost_and_usage(
        TimePeriod={
            'Start': start_str,
            'End': end_str
        },
        Granularity='MONTHLY',
        Metrics=['UnblendedCost']
    )

    # Get cost by service
    service_response = ce_client.get_cost_and_usage(
        TimePeriod={
            'Start': start_str,
            'End': end_str
        },
        Granularity='MONTHLY',
        Metrics=['UnblendedCost'],
        GroupBy=[
            {
                'Type': 'DIMENSION',
                'Key': 'SERVICE'
            }
        ]
    )

    # Extract total cost
    total_cost = 0
    if total_response['ResultsByTime']:
        total_cost = float(total_response['ResultsByTime'][0]['Total']['UnblendedCost']['Amount'])

    # Extract service costs
    service_costs = []
    if service_response['ResultsByTime']:
        for group in service_response['ResultsByTime'][0]['Groups']:
            service_name = group['Keys'][0]
            cost = float(group['Metrics']['UnblendedCost']['Amount'])
            if cost > 0.01:  # Only include services with cost > $0.01
                service_costs.append({
                    'service': service_name,
                    'cost': cost
                })

    # Sort services by cost (descending)
    service_costs.sort(key=lambda x: x['cost'], reverse=True)

    return {
        'total_cost': total_cost,
        'service_costs': service_costs,
        'period': f"{start_str} to {end_str}"
    }

def send_webhook_notification(webhook_url, billing_data):
    """
    Send billing data via webhook (Slack, Teams, Discord, etc.)
    """
    # Format the message
    total_cost = billing_data['total_cost']
    service_costs = billing_data['service_costs']
    period = billing_data['period']

    # Create message blocks
    message = {
        "blocks": [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": "🏦 AWS Billing Alert"
                }
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*Total Cost:* ${total_cost:.2f}\n*Period:* {period}"
                }
            }
        ]
    }

    # Add service breakdown if there are services
    if service_costs:
        service_text = "*Top Services:*\n"
        for service in service_costs[:10]:  # Show top 10 services
            service_text += f"• {service['service']}: ${service['cost']:.2f}\n"

        message["blocks"].append({
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": service_text
            }
        })

    # Send via webhook
    http = urllib3.PoolManager()
    response = http.request(
        'POST',
        webhook_url,
        body=json.dumps(message),
        headers={'Content-Type': 'application/json'}
    )

    if response.status != 200:
        raise Exception(f"Webhook failed with status {response.status}")

    print(f"Billing alert sent successfully. Total cost: ${total_cost:.2f}")