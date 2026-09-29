import boto3
import json
import os
from datetime import datetime, timedelta
def lambda_handler(event, context):
ce = boto3.client('ce', region_name='us-east-1')
s3 = boto3.client('s3')
end = datetime.now().strftime('%Y-%m-%d')
start = (datetime.now() - timedelta(days=7)).strftime('%Y-%m-%d')
response = ce.get_cost_and_usage(
TimePeriod={'Start': start, 'End': end},
Granularity='DAILY',
Metrics=['UnblendedCost'],
GroupBy=[{'Type': 'DIMENSION', 'Key': 'SERVICE'}]
)

html = '<html><body><h1>AWS Weekly Cost Report</h1>'
total = 0
for result in response['ResultsByTime']:
html += f'<h2>{result["TimePeriod"]["Start"]}</h2><ul>'
for group in result['Groups']:
service = group['Keys'][0]
cost = float(group['Metrics']['UnblendedCost']['Amount'])
total += cost
html += f'<li>{service}: ${cost:.4f}</li>'
html += '</ul>'
html += f'<h2>Total 7 days: ${total:.2f}</h2></body></html>'

bucket = os.environ['REPORT_BUCKET']
key = f'reports/cost-report-{end}.html'
s3.put_object(Bucket=bucket, Key=key, Body=html, ContentType='text/html')
return {'statusCode': 200, 'body': f'Report saved to s3://{bucket}/{key}'}