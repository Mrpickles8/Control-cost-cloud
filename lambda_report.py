import boto3
import os
from datetime import datetime, timedelta
from decimal import Decimal

def lambda_handler(event, context):
    ce = boto3.client('ce', region_name='us-east-1')
    s3 = boto3.client('s3')

    end_date = datetime.utcnow().date()
    start_date = end_date - timedelta(days=7)

    start = start_date.strftime('%Y-%m-%d')
    end = end_date.strftime('%Y-%m-%d')

    response = ce.get_cost_and_usage(
        TimePeriod={
            'Start': start,
            'End': end
        },
        Granularity='DAILY',
        Metrics=['UnblendedCost'],
        GroupBy=[
            {'Type': 'DIMENSION', 'Key': 'SERVICE'}
        ]
    )

    html = [
        '<html><body>',
        '<h1>AWS Weekly Cost Report</h1>',
        f'<p>Period: {start} to {end} (end exclusive)</p>'
    ]

    total = Decimal('0')

    for result in response['ResultsByTime']:
        html.append(
            f'<h2>{result["TimePeriod"]["Start"]}</h2><ul>'
        )

        for group in result['Groups']:
            service = group['Keys'][0]
            amount = Decimal(
                group['Metrics']['UnblendedCost']['Amount']
            )
            unit = group['Metrics']['UnblendedCost']['Unit']
            total += amount

            html.append(
                f'<li>{service}: {amount:.4f} {unit}</li>'
            )

        html.append('</ul>')

    html.append(f'<h2>Total for 7 days: ${total:.2f}</h2>')
    html.append('</body></html>')

    report_html = '\n'.join(html)

    bucket = os.environ['REPORT_BUCKET']
    key = f'reports/cost-report-{end}.html'

    s3.put_object(
        Bucket=bucket,
        Key=key,
        Body=report_html.encode('utf-8'),
        ContentType='text/html; charset=utf-8'
    )

    return {
        'statusCode': 200,
        'body': f'Report saved to s3://{bucket}/{key}'
    }