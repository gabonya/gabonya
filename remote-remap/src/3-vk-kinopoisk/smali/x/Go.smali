.class public Lx/Go;
.super Landroid/app/Activity;

.method public constructor <init>()V
    .registers 1
    invoke-direct {p0}, Landroid/app/Activity;-><init>()V
    return-void
.end method

.method protected onCreate(Landroid/os/Bundle;)V
    .registers 6
    invoke-super {p0, p1}, Landroid/app/Activity;->onCreate(Landroid/os/Bundle;)V
    invoke-virtual {p0}, Lx/Go;->getPackageManager()Landroid/content/pm/PackageManager;
    move-result-object v0
    const-string v1, "ru.kinopoisk.tv"
    invoke-virtual {v0, v1}, Landroid/content/pm/PackageManager;->getLeanbackLaunchIntentForPackage(Ljava/lang/String;)Landroid/content/Intent;
    move-result-object v2
    if-nez v2, :have
    invoke-virtual {v0, v1}, Landroid/content/pm/PackageManager;->getLaunchIntentForPackage(Ljava/lang/String;)Landroid/content/Intent;
    move-result-object v2
    if-eqz v2, :done
    :have
    const/high16 v3, 0x10000000
    invoke-virtual {v2, v3}, Landroid/content/Intent;->addFlags(I)Landroid/content/Intent;
    :try_start
    invoke-virtual {p0, v2}, Lx/Go;->startActivity(Landroid/content/Intent;)V
    :try_end
    .catch Ljava/lang/Exception; {:try_start .. :try_end} :done
    :done
    invoke-virtual {p0}, Lx/Go;->finish()V
    return-void
.end method
