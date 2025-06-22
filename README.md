# FDC-Server

A Ruby on Rails based api server 

*   Ruby version: 3.2+
*   Rails version: 7.1.x
*   Authentication and Authorization: JWT token

## Configuration

*   Rename `env_example` to `.env` and fill in the required environment variables:

    ```bash
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
3.  Start the server: `bin/rails server`

### Running the client-example 

*   `cd client-example`
*   `npm install`
*   `npm run dev`

