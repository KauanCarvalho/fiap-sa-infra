COMPOSE_DIR := local
NETWORK := shared_network

.DEFAULT_GOAL := help
.PHONY: up down logs ps clean-docker help

help:
	@echo ""
	@echo "Available commands:"
	@echo "  make up                 # Start local containers"
	@echo "  make down               # Stop and remove containers"
	@echo "  make logs               # Follow logs of all services"
	@echo "  make ps                 # Show container status"
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
