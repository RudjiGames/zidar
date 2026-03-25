/*
 * Zidar - Build system scripts.
 * Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
 * License: https://github.com/RudjiGames/rg_core/blob/master/LICENSE
 */

#include "04_Qt_app_using_a_library_pch.h"
#include "main_window.h"
#include <02_hello_library/include/hello_library.h>

int main(int argc, char* argv[])
{
    QApplication a(argc, argv);
    MainWindow w;
    w.show();
    QMessageBox::about(&w, QString("Call"), QString("2 + 3 = ") + QString::number(helloLibraryAdd(2, 3)));
    return a.exec();
}
