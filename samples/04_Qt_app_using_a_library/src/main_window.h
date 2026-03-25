/*
 * Zidar - Build system scripts
 * Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
 * License: https://github.com/RudjiGames/rg_core/blob/master/LICENSE
 */

#ifndef RG_MAIN_WINDOW_H
#define RG_MAIN_WINDOW_H

#include <QtWidgets/QMainWindow>

QT_BEGIN_NAMESPACE
namespace Ui {
    class MainWindow;
}
QT_END_NAMESPACE

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget* parent = nullptr);
    ~MainWindow();

private:
    Ui::MainWindow* ui;
};

#endif /* RG_MAIN_WINDOW_H */	
