# stupidchess-frontend

![active-game](board.png)

From the Stupid Chess homepage:

```
This is a web-based board game running on a python-flask/mongo backend with a react frontend. It
is deployed on a raspberry pi running in my house. Here's the salt configuration used to do that:
https://github.com/norwoodj/rpi-salt.

You can see the code for this project at https://github.com/norwoodj/stupidchess
You might also visit my other projects https://hashbash.jmn23.com and https://bolas.jmn23.com.
You can see my personal website at https://jmn23.com.

Stupid Chess is a variant on the popular Chess and checkers board games that John Norwood (that's me)
and some of his college friends invented when we stumbled across a chess board that had been ripped
in half and an incomplete set of pieces. It has a number of delightful rule changes over these earlier
inferior games, and you can learn how to play on this page
https://stupidchess.jmn23.com/how-to-play
```

### This Codebase

This code was largely written as an exploration of how to effectively build and deploy flask/mongo/react
projects as well as a way to get the rules of a game that I really enjoy codified in a meaningful way.

Additionally, I'm a professional software developer, and my hope is that you, dear recruiter, see this
as an indication of my skillset.

This codebase holds the frontend code for the stupidchess project, and relies on images built by
the related [backend project](https://github.com/norwoodj/stupidchess-backend).

### Building and Developing Locally

The main make target builds the distribution artifact, this has been tested with node version 18
most recently.

There is a docker-compose setup for running locally. To start run the following,
then navigate to http://localhost:23180 in your browser.

```
make run
```

This is setup to include local code changes in the running docker containers as volumes and to use auto-reload
with --watch for webpack. In this way your code will get rebuilt and the server
reloaded as you make changes.

### Releasing

There's a make target for releasing

```
make release
```

This is only tested on linux and requires you have installed some dependencies with:

```
sudo apt install git-buildpackage
```

### Building Debian Package

There's a make target for building this project's debian package

```
make deb
```

This is only tested on linux and requires you have installed some dependencies with:

```
sudo apt install devscripts debhelper
```
