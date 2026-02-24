/**
 * Test script for Las Vegas Food Curator Dashboard
 */
import { chromium } from 'playwright';
import { spawn } from 'child_process';
import path from 'path';
import fs from 'fs';

const PROJECT_DIR = '/workspace/lvfc_bot';

async function waitForServer(url, timeout = 30000) {
    const start = Date.now();
    while (Date.now() - start < timeout) {
        try {
            const response = await fetch(url);
            if (response.ok) return true;
        } catch {}
        await new Promise(r => setTimeout(r, 1000));
    }
    return false;
}

async function test() {
    console.log('Starting Streamlit dashboard test...');
    
    // Start the Streamlit server
    console.log('Launching Streamlit server...');
    const server = spawn('streamlit', ['run', 'dashboard.py', '--server.headless=true', '--server.port=8501'], {
        cwd: PROJECT_DIR,
        env: { ...process.env, PYTHONUNBUFFERED: '1' },
        stdio: ['ignore', 'pipe', 'pipe']
    });
    
    let serverOutput = '';
    server.stdout.on('data', (data) => {
        serverOutput += data.toString();
    });
    server.stderr.on('data', (data) => {
        serverOutput += data.toString();
    });
    
    // Wait for server to start
    console.log('Waiting for server to start...');
    await new Promise(r => setTimeout(r, 10));
    
    const serverReady = await waitForServer('http://localhost:8501', 30000);
    
    if (!serverReady) {
        console.error('Server failed to start');
        console.log('Server output:', serverOutput);
        server.kill();
        process.exit(1);
    }
    
    console.log('Server is ready!');
    
    // Test with Playwright
    console.log('Launching browser...');
    const browser = await chromium.launch({ 
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    
    try {
        const page = await browser.newPage();
        
        console.log('Navigating to dashboard...');
        await page.goto('http://localhost:8501', { waitUntil: 'networkidle', timeout: 30000 });
        
        console.log('Page loaded. Checking for key elements...');
        
        // Check for title
        const title = await page.title();
        console.log('Page title:', title);
        
        // Check for main content
        const body = await page.textContent('body');
        const hasLogin = body.includes('Login') || body.includes('login');
        const hasBot = body.includes('Bot') || body.includes('bot');
        
        console.log('Has login form:', hasLogin);
        console.log('Has bot status:', hasBot);
        
        // Check for any errors in console
        const errors = [];
        page.on('console', msg => {
            if (msg.type() === 'error') {
                errors.push(msg.text());
            }
        });
        
        // Wait a bit more to catch any errors
        await new Promise(r => setTimeout(r, 2000));
        
        if (errors.length > 0) {
            console.log('Console errors found:', errors);
        } else {
            console.log('No console errors!');
        }
        
        // Take screenshot
        // await page.screenshot({ path: '/workspace/lvfc_test.png', fullPage: true });
        // console.log('Screenshot saved to /workspace/lvfc_test.png');
        
        console.log('\n✅ Test completed successfully!');
        
    } catch (error) {
        console.error('Test failed:', error);
        process.exit(1);
    } finally {
        await browser.close();
        server.kill();
    }
}

test().catch(console.error);
