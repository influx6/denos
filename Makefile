BREW_CMD=`which brew`
HEROKU_CMD=`which heroku`
env =? development

setup: setup-homebrew setup-heroku setup-ruby install-deps 

install-deps:
	gem install bundle rails
	bundle install

setup-ruby:
	brew install rbenv ruby-build
	rbenv install 2.6.5
	rbenv global 2.6.5

setup-heroku:
ifeq ($(BREW_CMD),'')
	brew tap heroku/brew && brew install heroku
else
	@echo 'Heroku already installed'
	@exit 0
endif

setup-homebrew:
ifeq ($(BREW_CMD),'')
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
	@echo 'Homebrew already installed'
	@exit 0
endif

postgre:
   psql --host=localhost --port=5432 --username=starcraft  --dbname=denos

test: unit integration

unit:
	bundle exec rspec

integration:
	bundle exec rspec spec/lib/*

start: start-db
	bundle exec rails server

setup-db:
	rails db:setup RAILS_ENV=$(env)

start-db:
	docker-compose up -d

stop-db:
	docker-compose down
 
