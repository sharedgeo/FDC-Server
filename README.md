# FDC-Server

A Ruby on Rails based api server 

*   Ruby version: 3.2+
*   Rails version: 7.1.x
*   Authentication and Authorization: JWT token

## Configuration

*   Rename `env_example` to `.env` and fill in the required environment variables:

    ```bash
    PG_DB=
    PG_USER=
    PG_PASS=
    PG_HOST=
    PG_PORT=5432

    OIDC_ISSUER_URL=
    OIDC_API_AUDIENCE
    OIDC_JWKS_URL=
    ```

## Development

### Migrations

*   `bin/rails db:migrate`

### Development Setup

1.  Clone the repository.
2.  Install dependencies: `bundle install`
3.  Seed some data: `bin/rails db:seed`
4.  Start the server: `bin/rails server`

### Running the client example 

*   Created with node 24.1.0
*   `cd client-example`
*   `npm install`
*   `npm run dev`

### Running tests

*   `RAILS_ENV=test bundle exec rails db:drop db:create db:schema:load`
*   `bin/rails test`
