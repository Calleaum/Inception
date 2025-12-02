NAME=inception
COMPOSE=docker compose -f srcs/docker-compose.yml
ENV_FILE=srcs/.env

all: up

up:
	$(COMPOSE) --env-file $(ENV_FILE) up --build -d

down:
	$(COMPOSE) --env-file $(ENV_FILE) down

re: down up

logs:
	$(COMPOSE) --env-file $(ENV_FILE) logs -f

clean:
	$(COMPOSE) --env-file $(ENV_FILE) down -v

fclean: clean
	docker volume rm -f mariadb_data wordpress_data || true
	docker image rm -f $$(docker images --filter=reference='*nginx*' -q) || true
	docker image rm -f $$(docker images --filter=reference='*wordpress*' -q) || true
	docker image rm -f $$(docker images --filter=reference='*mariadb*' -q) || true
	docker image prune -f

rebuild: fclean up
