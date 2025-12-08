from django.db import models

class Jobs(models.Model):
    id = models.CharField(max_length=255, primary_key=True)
    site = models.CharField(max_length=255, null=True)
    job_url = models.CharField(max_length=1000, null=True)  # URLs can be long
    job_url_direct = models.CharField(max_length=1000, null=True)  # URLs can be long
    title = models.CharField(max_length=500, null=True)  # Job titles can be detailed
    company = models.CharField(max_length=255, null=True)
    location = models.CharField(max_length=255, null=True)
    date_posted = models.CharField(max_length=255, null=True)
    job_type = models.CharField(max_length=255, null=True)
    salary_source = models.CharField(max_length=255, null=True)
    interval = models.CharField(max_length=255, null=True)
    min_amount = models.CharField(max_length=255, null=True)
    max_amount = models.CharField(max_length=255, null=True)
    currency = models.CharField(max_length=255, null=True)
    is_remote = models.CharField(max_length=255, null=True)
    job_level = models.CharField(max_length=255, null=True)
    job_function = models.CharField(max_length=500, null=True)  # Can have multiple functions
    listing_type = models.CharField(max_length=255, null=True)
    emails = models.CharField(max_length=500, null=True)  # Multiple emails possible
    description = models.CharField(max_length=1000000, null=True)  # Job descriptions are long
    company_industry = models.CharField(max_length=255, null=True)
    company_url = models.CharField(max_length=1000, null=True)  # URLs can be long
    company_logo = models.CharField(max_length=1000, null=True)  # URLs can be long
    company_url_direct = models.CharField(max_length=1000, null=True)  # URLs can be long
    company_addresses = models.CharField(max_length=1000, null=True)  # Multiple addresses
    company_num_employees = models.CharField(max_length=255, null=True)
    company_revenue = models.CharField(max_length=255, null=True)
    company_description = models.CharField(max_length=5000, null=True)  # Company descriptions are long
    skills = models.CharField(max_length=2000, null=True)  # Multiple skills listed
    experience_range = models.CharField(max_length=255, null=True)
    company_rating = models.CharField(max_length=255, null=True)
    company_reviews_count = models.CharField(max_length=255, null=True)
    vacancy_count = models.CharField(max_length=255, null=True)
    work_from_home_type = models.CharField(max_length=255, null=True)
    jobs_scraped_at = models.CharField(max_length=255, null=True)
    batch_id = models.CharField(max_length=255, null=True)

    def __str__(self):
        return self.title or "Untitled Job"

    class Meta:
        verbose_name = "Job"
        verbose_name_plural = "Jobs"
        ordering = ['-jobs_scraped_at']