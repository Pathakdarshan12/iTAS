from django.core.management.base import BaseCommand
from jobspy import scrape_jobs
from home.models import Jobs 
from django.db import transaction 

class Command(BaseCommand):
    help = 'Scrapes job data and saves it to the database'

    def handle(self, *args, **kwargs):
        # Scrape jobs and get DataFrame
        jobs_df = scrape_jobs(
            site_name=["linkedin"],
            search_term="Full Stack Developer",
            location="Pune, Maharashtra, India",
            results_wanted=5,
            hours_old=24,
        )

        # Use transaction.atomic() to ensure atomicity of database operations
        with transaction.atomic():
            for index, job_data in jobs_df.iterrows():
                try:
                    # Create Jobs object from DataFrame row
                    Jobs.objects.create(
                        title=job_data['title'],
                        company=job_data['company'],
                        location=job_data['location'],
                        status=job_data['company'],
                        platform=job_data['site'],
                        link=job_data['job_url'],
                    )
                except Exception as e:
                    # Handle any errors that occur during object creation
                    self.stderr.write(f"Error creating Jobs object: {e}")

        self.stdout.write(self.style.SUCCESS('Job scraping completed successfully'))
