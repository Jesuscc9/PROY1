from django.db import models

class Quiz(models.Model):
    code = models.TextField()
    instruction = models.TextField()
    correct_code = models.TextField()

class Question(models.Model):
    quiz = models.ForeignKey(Quiz, on_delete=models.CASCADE)
    correct_option_key = models.CharField(max_length=10)
    correct_option_explanation = models.TextField()
    topic_id = models.IntegerField()

class Option(models.Model):
    question = models.ForeignKey(Question, on_delete=models.CASCADE)
    option_key = models.CharField(max_length=10)
    option_content = models.TextField()
