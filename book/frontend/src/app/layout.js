"use client";

import Link from "next/link";
import { AppBar, Toolbar, Container, Button, Box } from "@mui/material";
import { ThemeProvider, createTheme } from "@mui/material/styles";
import { useEffect, useState } from "react";

import "@fontsource/nanum-gothic";
import "@fontsource/gowun-dodum";

const theme = createTheme({
    typography: {
        fontFamily: "Gowun Dodum, sans-serif",
        h4: {
            fontFamily: "Nanum Gothic, sans-serif",
            fontWeight: 700,
        },
        h6: {
            fontFamily: "Nanum Gothic, sans-serif",
            fontWeight: 700,
        },
        button: {
            fontFamily: "Nanum Gothic, sans-serif",
            fontWeight: 700,
        },
    },
});

export default function RootLayout({ children }) {
    const [isLogin, setIsLogin] = useState(false);

    useEffect(() => {
        const user = localStorage.getItem("user");
        setIsLogin(!!user);
    }, []);

    const handleLogout = () => {
        const ok = window.confirm("정말 로그아웃 하시겠습니까?");
        if (!ok) return;

        localStorage.removeItem("user");
        setIsLogin(false);
        window.location.href = "/mainpage";
    };

    // 🔥 로그인 필요: 경고창 + 로그인 페이지 이동
    const requireLogin = (path) => {
        if (!isLogin) {
            alert("로그인이 필요한 서비스입니다.\n로그인 페이지로 이동합니다.");
            window.location.href = "/login"; // ⭐ 로그인 페이지로 이동
            return;
        }
        window.location.href = path; // 로그인 되어 있으면 이동
    };

    return (
        <html lang="ko">
        <body>
        <ThemeProvider theme={theme}>
            <AppBar position="static" sx={{ boxShadow: 2 }}>
                <Toolbar
                    sx={{
                        minHeight: 80,
                        display: "flex",
                        justifyContent: "space-between",
                    }}
                >
                    <Link href="/mainpage" passHref>
                        <Button color="inherit" sx={{ fontSize: 18, fontWeight: 700 }}>
                            도서 관리 시스템
                        </Button>
                    </Link>

                    <Box sx={{ display: "flex", gap: 2 }}>
                        {!isLogin ? (
                            <Link href="/login" passHref>
                                <Button color="inherit">로그인</Button>
                            </Link>
                        ) : (
                            <Button color="inherit" onClick={handleLogout}>
                                로그아웃
                            </Button>
                        )}

                        {/* 🔐 로그인 필요 기능들 */}
                        <Button
                            color="inherit"
                            onClick={() => requireLogin("/userpage/view")}
                        >
                            내 작품 관리
                        </Button>

                        <Button
                            color="inherit"
                            onClick={() => requireLogin("/userpage/create")}
                        >
                            새 작품 등록
                        </Button>
                    </Box>
                </Toolbar>
            </AppBar>

            <Container maxWidth="md" sx={{ mt: 4 }}>
                {children}
            </Container>
        </ThemeProvider>
        </body>
        </html>
    );
}
