# Rails Issues Browser
Goal is to build a rudimentary service that allowed the end user to interact with
the rails repository issues, particularly:

- Filtering by a predefined set of labels.
- Sorting by:
  - Creation timestamp ( CREATED_AT )
  - Number of comments ( COMMENTS )

## Setup

1. Install dependencies: `bundle install`.
2. Copy .env.example into .env `cp .env.example .env`.
3. Install github token in .env file, intructions [here](https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line)
4. Run server `ruby app.rb`
5. Access service via http://localhost:4567, accepts both browsers and json clients.

## Rationale

### Server Framework

Based on my experience, using rails provides lots of goodies out of the box but
seemed a little overkill in both size and dependencies for building a single
endpoint.

I chose to use Sinatra instead, which is a minimal http framework, in the worst
case scenario, porting this code to Rails should be a breeze if needed.

### Github's API

Next thing was to know which Github API I should interact with, so I had two
options:
- REST (V3)
- GraphQL (V4)

I have little hands-on experience with GraphQL so I decided to first try the V3.

While reading the V3 documentation found out that this version treats issues and
pull requests as the same resource so filtering out the pull requests would
result in additional client overhead and medium/long term complications.

I think this is a bad design choice made by Github, but totally understand their
position, this is most probably intentional behaviour in order to keep
backward compatibility with existing users.

So decided to try GraphQL instead, been using JSON:API specification in my last
couple projects, which I understand has similar capabilities, so decided to try
GraphQL and see with my own eyes the goodies everyone is talking about.

### Libraries

- Backend:
  - ActiveSupport: Useful for manipulating data before showing it to the user.
  - Bundler: Useful for dependency management.
  - Dotenv: Used to follow industry's best practices to store credentials in the
    environment ( https://12factor.net ).
  - GraphQL Client: Used since github itself is the maintainer of this library,
    gets the job done and is under constant maintenance.
- Frontend:
  - Bootstrap: Widely used for quick ui prototyping.
  - Jquery: Useful for quick dom manipulations.

### Application

Decided to build a single index view with the following parameters:

- Filtering
  - By Labels
  - By States
- Sorting
  - By Field
  - By Direction
- Plus
  - Pagination
  - JSON:API'ish response if client request application/json
  - Repository Selection ( Not implemented, but ready to implement )

Used defensive programming techniques to catch invalid values for the parameters
and defined a set of default values for these in case an invalid value was
detected.

When hitting github's api added error handling for common errors:

- Network Failure
- Network Timeout
- Bad Requests

Third party API testing was performed first in Insomnia and then appropiate
request was copied into this codebase.

And finally, the index response would render.

If html is accepted, we will render a simple bootstrap page that has filters,
data table, pagination and required javascript code to make it all work.

If json is accepted, we will render a JSON:API'ish response.
