.class final Lcom/pairip/VmDecryptor;
.super Ljava/lang/Object;
.source "VmDecryptor.java"


# direct methods
.method public constructor <init>()V
    .locals 0

    .line 6
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method


# virtual methods
.method public decrypt([BIZ)[B
    .locals 0
    .annotation system Ldalvik/annotation/MethodParameters;
        accessFlags = {
            0x0,
            0x0,
            0x0
        }
        names = {
            "encryptedBytecode",
            "versionCode",
            "isDebuggingEnabled"
        }
    .end annotation

    return-object p1
.end method
