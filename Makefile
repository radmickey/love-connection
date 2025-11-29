.PHONY: help setup start stop restart logs backend db-migrate clean

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Initial setup - install dependencies and prepare environment
	@echo "Setting up project..."
	@cd backend && go mod download
	@if [ ! -f .env ]; then \
		cp backend/.env.example .env; \
		echo "Created .env file from example. Please update it with your values."; \
	fi
	@echo "Setup complete!"

start: ## Start all services (PostgreSQL + Backend)
	@echo "Starting services..."
	docker-compose up -d
	@echo "Services started! Backend should be available at http://localhost:8080"

stop: ## Stop all services
	@echo "Stopping services..."
	docker-compose down
	@echo "Services stopped"

restart: stop start ## Restart all services

logs: ## Show logs from all services
	docker-compose logs -f

logs-backend: ## Show backend logs only
	docker-compose logs -f backend

logs-db: ## Show database logs only
	docker-compose logs -f postgres

backend: ## Run backend locally (without Docker)
	@echo "Starting backend locally..."
	@cd backend && go run cmd/server/main.go

db-migrate: ## Run database migrations manually
	@echo "Running migrations..."
	@cd backend && go run cmd/server/main.go --migrate-only || echo "Note: Migrations run automatically on server start"

db-shell: ## Open PostgreSQL shell
	docker-compose exec postgres psql -U postgres -d loveconnection

db-create-test-pair-request: ## Create test user and send pair request to radmickey
	@echo "Creating test user and pair request..."
	@docker-compose exec -T postgres psql -U postgres -d loveconnection < scripts/create_test_pair_request_simple.sql
	@echo "Done! Check the result above."

db-reset: ## Reset database (WARNING: deletes all data)
	@read -p "Are you sure you want to reset the database? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose down -v; \
		docker-compose up -d postgres; \
		sleep 3; \
		docker-compose up -d backend; \
		echo "Database reset complete"; \
	fi

clean: ## Clean up Docker volumes and containers
	docker-compose down -v
	@echo "Cleaned up!"

test-backend: ## Run backend tests
	@cd backend && go test ./...

build-backend: ## Build backend binary
	@cd backend && go build -o bin/server ./cmd/server

dev: ## Start in development mode with hot reload (requires air: go install github.com/cosmtrek/air@latest)
	@cd backend && air

