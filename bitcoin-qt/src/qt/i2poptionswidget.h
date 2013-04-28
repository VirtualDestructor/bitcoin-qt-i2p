#ifndef I2POPTIONSWIDGET_H
#define I2POPTIONSWIDGET_H

#include <QWidget>

class MonitoredDataMapper;

namespace Ui {
class I2POptionsWidget;
}

class I2POptionsWidget : public QWidget
{
    Q_OBJECT
    
public:
    explicit I2POptionsWidget(QWidget *parent = 0);
    ~I2POptionsWidget();

    void setMapper(MonitoredDataMapper& mapper);
    
private:
    Ui::I2POptionsWidget *ui;

private slots:
    void ShowCurrentI2PAddress();
    void GenerateNewI2PAddress();

signals:
    void settingsChanged();
};

#endif // I2POPTIONSWIDGET_H
