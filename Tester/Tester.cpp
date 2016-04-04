// Tester.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"


int main()
{
    Media::loadFileMap("media");
    Game *game = new Game(1280, 720);
    game->start();
    game->invoke([]() {
        printf("abc");
    });
    while (!game->shouldClose);
    return 0;
}
