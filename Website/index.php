<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VulnCorp Inc. — Trusted Enterprise Solutions</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #0a0e17;
            color: #e0e6f0;
            min-height: 100vh;
        }

        /* ── Navbar ───────────────────────────────── */
        nav {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 1.2rem 4rem;
            background: rgba(10, 14, 23, 0.95);
            border-bottom: 1px solid rgba(59, 130, 246, 0.2);
            position: sticky;
            top: 0;
            z-index: 100;
            backdrop-filter: blur(12px);
        }
        .logo {
            font-size: 1.5rem;
            font-weight: 700;
            background: linear-gradient(135deg, #3b82f6, #8b5cf6);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            letter-spacing: -0.5px;
        }
        .nav-links a {
            color: #94a3b8;
            text-decoration: none;
            margin-left: 2rem;
            font-size: 0.9rem;
            transition: color 0.2s;
        }
        .nav-links a:hover { color: #3b82f6; }

        /* ── Hero ─────────────────────────────────── */
        .hero {
            text-align: center;
            padding: 8rem 2rem 6rem;
            background:
                radial-gradient(ellipse at 50% 0%, rgba(59,130,246,0.15) 0%, transparent 60%),
                radial-gradient(ellipse at 80% 50%, rgba(139,92,246,0.08) 0%, transparent 50%);
        }
        .hero h1 {
            font-size: 3.2rem;
            font-weight: 800;
            line-height: 1.15;
            margin-bottom: 1.5rem;
        }
        .hero h1 span {
            background: linear-gradient(135deg, #3b82f6, #8b5cf6, #ec4899);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
        .hero p {
            font-size: 1.15rem;
            color: #94a3b8;
            max-width: 600px;
            margin: 0 auto 2.5rem;
            line-height: 1.7;
        }
        .cta-btn {
            display: inline-block;
            padding: 0.85rem 2.2rem;
            background: linear-gradient(135deg, #3b82f6, #8b5cf6);
            color: #fff;
            border-radius: 8px;
            text-decoration: none;
            font-weight: 600;
            font-size: 1rem;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .cta-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 30px rgba(59,130,246,0.3);
        }

        /* ── Features ─────────────────────────────── */
        .features {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 2rem;
            padding: 4rem;
            max-width: 1100px;
            margin: 0 auto;
        }
        .card {
            background: rgba(30, 41, 59, 0.5);
            border: 1px solid rgba(59,130,246,0.15);
            border-radius: 12px;
            padding: 2rem;
            transition: border-color 0.3s, transform 0.2s;
        }
        .card:hover {
            border-color: rgba(59,130,246,0.4);
            transform: translateY(-4px);
        }
        .card .icon { font-size: 2rem; margin-bottom: 1rem; }
        .card h3 {
            font-size: 1.15rem;
            margin-bottom: 0.6rem;
            color: #f1f5f9;
        }
        .card p {
            font-size: 0.9rem;
            color: #94a3b8;
            line-height: 1.6;
        }

        /* ── Footer ───────────────────────────────── */
        footer {
            text-align: center;
            padding: 3rem 2rem;
            border-top: 1px solid rgba(59,130,246,0.1);
            color: #475569;
            font-size: 0.85rem;
        }
    </style>
</head>
<body>

<nav>
    <div class="logo">VulnCorp</div>
    <div class="nav-links">
        <a href="#">Solutions</a>
        <a href="#">About</a>
        <a href="#">Careers</a>
        <a href="#">Contact</a>
    </div>
</nav>

<section class="hero">
    <h1>Enterprise Infrastructure<br><span>You Can Trust</span></h1>
    <p>VulnCorp delivers next-generation network security, cloud integration, and managed IT services for organizations that demand reliability.</p>
    <a href="#" class="cta-btn">Request a Demo</a>
</section>

<section class="features">
    <div class="card">
        <div class="icon">&#128274;</div>
        <h3>Network Security</h3>
        <p>Multi-layered perimeter defense with advanced threat detection across all network segments.</p>
    </div>
    <div class="card">
        <div class="icon">&#9729;&#65039;</div>
        <h3>Cloud Integration</h3>
        <p>Seamless hybrid-cloud solutions with OwnCloud and MinIO for secure object storage.</p>
    </div>
    <div class="card">
        <div class="icon">&#128231;</div>
        <h3>Mail Gateway</h3>
        <p>Enterprise email routing with spam filtering, DKIM signing, and LDAP authentication.</p>
    </div>
    <div class="card">
        <div class="icon">&#128450;</div>
        <h3>Backup & Recovery</h3>
        <p>Automated rsync and NFS-based backup across all network zones with point-in-time recovery.</p>
    </div>
</section>

<footer>
    &copy; <?php echo date('Y'); ?> VulnCorp Inc. All rights reserved.
    <!-- Server: <?php echo php_uname(); ?> -->
</footer>

</body>
</html>
