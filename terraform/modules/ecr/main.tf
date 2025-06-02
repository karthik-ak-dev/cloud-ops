resource "aws_ecr_repository" "this" {
  for_each = toset(var.repository_names)

  name                 = "${var.project_name}-${each.key}"
  image_tag_mutability = var.image_tag_mutability
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = {
    Name = "${var.project_name}-${each.key}"
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = toset(var.repository_names)

  repository = aws_ecr_repository.this[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only ${var.max_image_count} images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = var.max_image_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Optionally create a repository policy
resource "aws_ecr_repository_policy" "this" {
  for_each = var.create_repository_policy ? toset(var.repository_names) : []

  repository = aws_ecr_repository.this[each.key].name
  policy     = var.repository_policy
}
