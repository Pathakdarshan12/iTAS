import csv
import uuid
import hashlib
import time
from django.core.management.base import BaseCommand
from django.db import transaction
from jobspy import scrape_jobs
from home.models import Jobs
from datetime import datetime

class Command(BaseCommand):
    help = 'Scrapes job data and saves it to the database'

    def handle(self, *args, **options):
        # Fixed parameters
        search_term = 'data engineer'
        location = 'Pune, Maharashtra, India'
        results_wanted = 10000

        # Generate batch ID for this scraping session
        batch_id = str(uuid.uuid4())
        scraped_at = datetime.now().isoformat()

        self.stdout.write(f'Starting job scraping for: {search_term}')

        # Scrape jobs
        try:
            jobs_df = scrape_jobs(
                site_name=["indeed", "linkedin", "zip_recruiter", "google"],
                search_term=search_term,
                google_search_term=f"{search_term} jobs near {location} since yesterday",
                location=location,
                results_wanted=results_wanted,
                hours_old=200,
                country_indeed='India',
            )

            timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
            filename = f"jobs_{timestamp}.csv"

            # Save to CSV for backup
            jobs_df.to_csv(
                filename,
                sep="|",
                quoting=csv.QUOTE_NONNUMERIC,
                escapechar="\\",
                index=False
            )
            self.stdout.write(self.style.SUCCESS(f'Saved {len(jobs_df)} jobs to {filename}'))

        except Exception as e:
            self.stderr.write(self.style.ERROR(f'Error during scraping: {e}'))
            return

        # Save to database
        created_count = 0
        skipped_count = 0
        error_count = 0

        # Helper function to truncate long strings
        def safe_str(value, max_length=1000000):
            """Convert value to string and truncate if needed"""
            if value is None or (isinstance(value, float) and value != value):  # Check for NaN
                return ''
            text = str(value)
            return text[:max_length] if len(text) > max_length else text

        # Generate unique IDs
        def generate_job_id(row, index):
            """Generate a unique ID for the job"""
            # Try to use existing ID from scraper
            raw_id = row.get('id')
            if raw_id is not None and not (isinstance(raw_id, float) and raw_id != raw_id):  # Not None and not NaN
                str_id = str(raw_id).strip()
                if str_id:  # Not empty after stripping
                    return str_id[:255]  # Ensure it fits in the field

            # Create ID from job_url if available
            job_url = row.get('job_url')
            if job_url is not None and str(job_url).strip():
                # Use hash of URL for consistent ID
                url_hash = hashlib.md5(str(job_url).encode()).hexdigest()[:16]
                return f"job-{url_hash}"

            # Fallback: create ID from batch_id, index and timestamp
            timestamp = str(int(time.time() * 1000000))[-10:]
            return f"{batch_id[:8]}-{index:04d}-{timestamp}"

        for index, row in jobs_df.iterrows():
            try:
                # Check if job already exists (by job_url to avoid duplicates)
                job_url = safe_str(row.get('job_url', ''))
                if job_url and Jobs.objects.filter(job_url=job_url).exists():
                    skipped_count += 1
                    continue

                # Create Jobs object with transaction per record
                with transaction.atomic():
                    Jobs.objects.create(
                        id=generate_job_id(row, index),
                        site=safe_str(row.get('site', '')),
                        job_url=job_url,
                        job_url_direct=safe_str(row.get('job_url_direct', '')),
                        title=safe_str(row.get('title', '')),
                        company=safe_str(row.get('company', '')),
                        location=safe_str(row.get('location', '')),
                        date_posted=safe_str(row.get('date_posted', '')),
                        job_type=safe_str(row.get('job_type', '')),
                        salary_source=safe_str(row.get('salary_source', '')),
                        interval=safe_str(row.get('interval', '')),
                        min_amount=safe_str(row.get('min_amount', '')),
                        max_amount=safe_str(row.get('max_amount', '')),
                        currency=safe_str(row.get('currency', '')),
                        is_remote=safe_str(row.get('is_remote', '')),
                        job_level=safe_str(row.get('job_level', '')),
                        job_function=safe_str(row.get('job_function', '')),
                        listing_type=safe_str(row.get('listing_type', '')),
                        emails=safe_str(row.get('emails', '')),
                        description=safe_str(row.get('description', ''), max_length=5000),
                        company_industry=safe_str(row.get('company_industry', '')),
                        company_url=safe_str(row.get('company_url', '')),
                        company_logo=safe_str(row.get('company_logo', '')),
                        company_url_direct=safe_str(row.get('company_url_direct', '')),
                        company_addresses=safe_str(row.get('company_addresses', '')),
                        company_num_employees=safe_str(row.get('company_num_employees', '')),
                        company_revenue=safe_str(row.get('company_revenue', '')),
                        company_description=safe_str(row.get('company_description', ''), max_length=1000),
                        skills=safe_str(row.get('skills', ''), max_length=1000),
                        experience_range=safe_str(row.get('experience_range', '')),
                        company_rating=safe_str(row.get('company_rating', '')),
                        company_reviews_count=safe_str(row.get('company_reviews_count', '')),
                        vacancy_count=safe_str(row.get('vacancy_count', '')),
                        work_from_home_type=safe_str(row.get('work_from_home_type', '')),
                        jobs_scraped_at=scraped_at,
                        batch_id=batch_id,
                    )
                created_count += 1

            except Exception as e:
                error_count += 1
                self.stderr.write(f"Error creating job (row {index}): {e}")

        # Summary
        self.stdout.write(self.style.SUCCESS(
            f'\n=== Scraping Summary ===\n'
            f'Total scraped: {len(jobs_df)}\n'
            f'Created: {created_count}\n'
            f'Skipped (duplicates): {skipped_count}\n'
            f'Errors: {error_count}\n'
            f'Batch ID: {batch_id}\n'
        ))