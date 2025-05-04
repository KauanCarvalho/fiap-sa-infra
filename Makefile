COMPOSE_DIR := local
NETWORK := shared_network

.DEFAULT_GOAL := help
.PHONY: up down logs ps clean-docker help create-sns-sqs

help:
	@echo ""
	@echo "Available commands:"
	@echo "  make up                 # Start local containers"
	@echo "  make down               # Stop and remove containers"
	@echo "  make logs               # Follow logs of all services"
	@echo "  make ps                 # Show container status"
	@echo "  make create-sns-sqs     # Create SNS topic and SQS queue in LocalStack"
	@echo "  make clean-docker       # Clean up all Docker containers, images, and volumes"
	@echo ""

up:
	@echo "🔧 Starting local environment..."
	@docker network inspect $(NETWORK) >/dev/null 2>&1 || docker network create $(NETWORK)
	docker-compose -f $(COMPOSE_DIR)/docker-compose.yml up -d

down:
	@echo "🛑 Stopping local environment..."
	docker-compose -f $(COMPOSE_DIR)/docker-compose.yml down

logs:
	@echo "📜 Showing logs..."
	docker-compose -f $(COMPOSE_DIR)/docker-compose.yml logs -f

ps:
	@docker-compose -f $(COMPOSE_DIR)/docker-compose.yml ps

create-sns-sqs:
	@echo "📬 Creating SNS topic and SQS queue in LocalStack (idempotent)..."
	@if ! docker exec fiap_sa_localstack awslocal sns list-topics --query "Topics[*].TopicArn" --output text | grep -q "fiap_sa_payment_service_payment_events"; then \
		echo "🔧 Creating SNS topic 'fiap_sa_payment_service_payment_events'..."; \
		docker exec fiap_sa_localstack awslocal sns create-topic --name fiap_sa_payment_service_payment_events; \
	else \
		echo "✅ SNS topic 'fiap_sa_payment_service_payment_events' already exists."; \
	fi

	@if ! docker exec fiap_sa_localstack awslocal sqs list-queues --query "QueueUrls" --output text | grep -q "fiap_sa_order_service_payment_events"; then \
		echo "🔧 Creating SQS queue 'fiap_sa_order_service_payment_events'..."; \
		docker exec fiap_sa_localstack awslocal sqs create-queue --queue-name fiap_sa_order_service_payment_events; \
	else \
		echo "✅ SQS queue 'fiap_sa_order_service_payment_events' already exists."; \
	fi

	@docker exec fiap_sa_localstack bash -c '\
		TOPIC_ARN=$$(awslocal sns list-topics --query "Topics[?contains(TopicArn, \`fiap_sa_payment_service_payment_events\`)].TopicArn" --output text); \
		QUEUE_URL=$$(awslocal sqs get-queue-url --queue-name fiap_sa_order_service_payment_events --query "QueueUrl" --output text); \
		QUEUE_ARN=$$(awslocal sqs get-queue-attributes --queue-url $$QUEUE_URL --attribute-names QueueArn --query "Attributes.QueueArn" --output text); \
		if ! awslocal sns list-subscriptions-by-topic --topic-arn $$TOPIC_ARN --query "Subscriptions[*].Endpoint" --output text | grep -q $$QUEUE_ARN; then \
			echo "🔗 Subscribing 'fiap_sa_order_service_payment_events' to 'fiap_sa_payment_service_payment_events'..."; \
			awslocal sns subscribe --topic-arn $$TOPIC_ARN --protocol sqs --notification-endpoint $$QUEUE_ARN; \
			echo "📫 Subscription created successfully."; \
		else \
			echo "✅ Queue is already subscribed to the topic."; \
		fi \
	'

clean-docker:
	@echo "🧨 Stopping all containers..."
	@docker stop $$(docker ps -q) || true

	@echo "🧼 Removing all containers..."
	@docker rm $$(docker ps -aq) || true

	@echo "🗑️ Removing all images..."
	@docker rmi -f $$(docker images -q) || true

	@echo "🪣 Removing all volumes..."
	@docker volume rm $$(docker volume ls -q) || true

	@echo "🌐 Removing all custom networks..."
	@docker network rm $$(docker network ls --filter "type=custom" -q) || true

	@echo "🧹 Pruning system (dangling resources)..."
	@docker system prune -a --volumes -f

	@echo "✅ Docker cleanup complete."
