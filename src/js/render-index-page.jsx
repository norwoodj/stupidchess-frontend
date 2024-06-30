import $ from "jquery";
import React from "react";
import ReactDOM from "react-dom";

import Container from "muicss/lib/react/container";
import Panel from "muicss/lib/react/panel";
import ScAppBar from "./components/app-bar";
import SideDrawer from "./components/side-drawer";
import Footer from "./components/footer";

import { setupSideDrawerTransition } from "./side-drawer-transition";
import { MENU_CATEGORIES, APP_NAME } from "./constants";
import { setupCsrfRequests } from "./util";

$(() => {
    let currentUsername = $("#current-user").data("name");
    setupCsrfRequests();

    ReactDOM.render(
        <div id="react-root">
            <SideDrawer pageName={APP_NAME} menuCategories={MENU_CATEGORIES} />
            <ScAppBar
                appName={APP_NAME}
                httpService={$}
                currentUsername={currentUsername}
            />
            <div id="content-wrapper">
                <div className="mui--appbar-height"></div>
                <Container className="main-container">
                    <Panel>
                        <h2>Welcome to Stupid Chess!</h2>
                        <div className="mui-divider"></div>
                        <br />
                        <p>
                            This is a web-based board game running on a
                            python-flask/mongo backend with a react frontend. It
                            is deployed on a raspberry pi running in my house.
                            Here&apos;s the <a href="https://github.com/norwoodj/rpi-salt">salt configuration</a>{" "}
                            used to do that.
                        </p>
                        <p>
                           You can see the code for this project{" "}
                            <a href="https://github.com/norwoodj/stupidchess">
                                here
                            </a>
                            .
                        </p>
                        <p>
                            You might also visit my other projects{" "}
                            <a href="https://hashbash.jmn23.com">hashbash</a> and{" "}
                            <a href="https://bolas.jmn23.com">bolas</a>. My
                            personal website can be found <a href="https://jmn23.com">here</a>.
                        </p>
                        <img src="/img/screenshots/after-board-setup.jpg" />
                        <p>
                            Stupid Chess is a variant on the popular Chess and
                            checkers board games that John Norwood (that&apos;s me)
                            and some of his college friends invented when we
                            stumbled across a chess board that had been ripped
                            in half and an incomplete set of pieces. It has a
                            number of delightful rule changes over these earlier
                            inferior games, and you can learn how to play on
                            this page <a href="/how-to-play">here</a>.
                        </p>
                        <p>
                            In addition to Stupid Chess, you can also play chess
                            and Checkers using this website. The profile page
                            will track your stats and currently active games.
                            You can do a number of things from here:
                        </p>
                        <ul>
                            <li>
                                <a href="/how-to-play">
                                    Learn to Play Stupid Chess
                                </a>
                            </li>
                            <li>
                                <a href="/create-account">Create Account</a>
                            </li>
                            <li>
                                <a href="/create-game">Start A Game</a> (Login
                                Required)
                            </li>
                            <li>
                                <a href="/profile">Visit your profile</a> (Login
                                Required)
                            </li>
                        </ul>
                    </Panel>
                </Container>
            </div>
            <div className="footer-height"></div>
            <Footer />
        </div>,
        document.getElementById("content-root")
    );

    setupSideDrawerTransition();
});
