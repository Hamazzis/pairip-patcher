.class public Lcom/pairip/SignatureCheck;
.super Ljava/lang/Object;
.source "SignatureCheck.java"


# annotations
.annotation system Ldalvik/annotation/MemberClasses;
    value = {
        Lcom/pairip/SignatureCheck$SignatureTamperedException;
    }
.end annotation


# static fields
.field private static final ALLOWLISTED_SIG:Ljava/lang/String; = "Vn3kj4pUblROi2S+QfRRL9nhsaO2uoHQg6+dpEtxdTE="

.field private static final TAG:Ljava/lang/String; = "SignatureCheck"

.field private static expectedLegacyUpgradedSignature:Ljava/lang/String; = "Mb5ACW+THNfxHV4mLSssQ3xEOF+07LwQE9ladDWBb5w="

.field private static expectedSignature:Ljava/lang/String; = "Mb5ACW+THNfxHV4mLSssQ3xEOF+07LwQE9ladDWBb5w="

.field private static expectedTestSignature:Ljava/lang/String; = "Mb5ACW+THNfxHV4mLSssQ3xEOF+07LwQE9ladDWBb5w="


# direct methods
.method private constructor <init>()V
    .locals 0

    .line 77
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method public static verifyIntegrity(Landroid/content/Context;)V
    .locals 2

    const-string v0, "SignatureCheck"

    const-string v1, "Signature check bypassed by patch"

    invoke-static {v0, v1}, Landroid/util/Log;->i(Ljava/lang/String;Ljava/lang/String;)I

    return-void
.end method

.method public static verifySignatureMatches(Ljava/lang/String;)Z
    .locals 1
    .annotation system Ldalvik/annotation/MethodParameters;
        accessFlags = {
            0x0
        }
        names = {
            "signature"
        }
    .end annotation

    .line 74
    sget-object v0, Lcom/pairip/SignatureCheck;->expectedSignature:Ljava/lang/String;

    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result v0

    if-nez v0, :cond_1

    sget-object v0, Lcom/pairip/SignatureCheck;->expectedLegacyUpgradedSignature:Ljava/lang/String;

    invoke-virtual {v0, p0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z

    move-result p0

    if-eqz p0, :cond_0

    goto :goto_0

    :cond_0
    const/4 p0, 0x0

    return p0

    :cond_1
    :goto_0
    const/4 p0, 0x1

    return p0
.end method
