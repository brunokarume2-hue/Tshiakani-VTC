#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🏛️ Agent Architecte Principal - Tshiakani VTC

Système d'analyse et de recommandations architecturales pour le projet Tshiakani VTC.
Analyse l'architecture iOS (Swift), Backend (Node.js) et Dashboard (React).
"""

import os
import json
import re
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, asdict
from collections import defaultdict
import subprocess

@dataclass
class ArchitectureReport:
    """Rapport d'architecture complet"""
    timestamp: str
    version: str
    ios_analysis: Dict
    backend_analysis: Dict
    dashboard_analysis: Dict
    recommendations: List[Dict]
    metrics: Dict
    quality_score: float

class IOSAnalyzer:
    """Analyseur pour l'application iOS (Swift)"""
    
    def __init__(self, project_path: Path):
        self.project_path = project_path
        self.ios_path = project_path / "Tshiakani VTC"
        
    def analyze(self) -> Dict:
        """Analyse complète de l'architecture iOS"""
        analysis = {
            "structure": self._analyze_structure(),
            "services": self._analyze_services(),
            "views": self._analyze_views(),
            "models": self._analyze_models(),
            "viewmodels": self._analyze_viewmodels(),
            "patterns": self._analyze_patterns(),
            "dependencies": self._analyze_dependencies(),
            "code_quality": self._analyze_code_quality(),
            "metrics": self._calculate_metrics()
        }
        return analysis
    
    def _analyze_structure(self) -> Dict:
        """Analyse la structure du projet iOS"""
        structure = {
            "models": [],
            "views": [],
            "viewmodels": [],
            "services": [],
            "extensions": [],
            "resources": []
        }
        
        if not self.ios_path.exists():
            return structure
        
        # Analyser les dossiers
        for item in self.ios_path.iterdir():
            if item.is_dir():
                if item.name == "Models":
                    structure["models"] = [f.name for f in item.glob("*.swift")]
                elif item.name == "Views":
                    structure["views"] = self._count_swift_files_recursive(item)
                elif item.name == "ViewModels":
                    structure["viewmodels"] = [f.name for f in item.glob("*.swift")]
                elif item.name == "Services":
                    structure["services"] = [f.name for f in item.glob("*.swift")]
                elif item.name == "Extensions":
                    structure["extensions"] = [f.name for f in item.glob("*.swift")]
                elif item.name == "Resources":
                    structure["resources"] = self._analyze_resources(item)
        
        return structure
    
    def _count_swift_files_recursive(self, directory: Path) -> List[str]:
        """Compte récursivement les fichiers Swift"""
        files = []
        for item in directory.rglob("*.swift"):
            files.append(str(item.relative_to(self.ios_path)))
        return files
    
    def _analyze_resources(self, resources_path: Path) -> Dict:
        """Analyse les ressources"""
        resources = {
            "colors": [],
            "fonts": [],
            "localization": [],
            "assets": []
        }
        
        for item in resources_path.rglob("*"):
            if item.is_file():
                if "Colors" in str(item):
                    resources["colors"].append(item.name)
                elif "Fonts" in str(item):
                    resources["fonts"].append(item.name)
                elif "Localization" in str(item):
                    resources["localization"].append(item.name)
                elif item.suffix in [".png", ".jpg", ".jpeg", ".pdf"]:
                    resources["assets"].append(item.name)
        
        return resources
    
    def _analyze_services(self) -> Dict:
        """Analyse les services iOS"""
        services_path = self.ios_path / "Services"
        services = {
            "count": 0,
            "list": [],
            "patterns": [],
            "singletons": []
        }
        
        if not services_path.exists():
            return services
        
        for service_file in services_path.glob("*.swift"):
            services["count"] += 1
            services["list"].append(service_file.name)
            
            # Analyser le contenu
            content = service_file.read_text(encoding='utf-8', errors='ignore')
            
            # Détecter les singletons
            if "static let shared" in content or "static var shared" in content:
                services["singletons"].append(service_file.stem)
            
            # Détecter les patterns
            if "@Published" in content:
                services["patterns"].append("ObservableObject")
            if "async" in content and "await" in content:
                services["patterns"].append("Async/Await")
            if "Combine" in content:
                services["patterns"].append("Combine")
        
        return services
    
    def _analyze_views(self) -> Dict:
        """Analyse les vues SwiftUI"""
        views_path = self.ios_path / "Views"
        views = {
            "count": 0,
            "by_category": defaultdict(int),
            "components": [],
            "patterns": []
        }
        
        if not views_path.exists():
            return views
        
        for view_file in views_path.rglob("*.swift"):
            views["count"] += 1
            category = view_file.parent.name
            views["by_category"][category] += 1
            
            if "Components" in str(view_file):
                views["components"].append(str(view_file.relative_to(self.ios_path)))
            
            # Analyser les patterns
            content = view_file.read_text(encoding='utf-8', errors='ignore')
            if "@StateObject" in content:
                views["patterns"].append("MVVM")
            if "@State" in content:
                views["patterns"].append("State Management")
        
        return dict(views)
    
    def _analyze_models(self) -> Dict:
        """Analyse les modèles de données"""
        models_path = self.ios_path / "Models"
        models = {
            "count": 0,
            "list": [],
            "codable": [],
            "properties": defaultdict(int)
        }
        
        if not models_path.exists():
            return models
        
        for model_file in models_path.glob("*.swift"):
            models["count"] += 1
            models["list"].append(model_file.stem)
            
            content = model_file.read_text(encoding='utf-8', errors='ignore')
            
            if "Codable" in content or ": Codable" in content:
                models["codable"].append(model_file.stem)
            
            # Compter les propriétés
            properties = re.findall(r'(var|let)\s+(\w+)', content)
            models["properties"][model_file.stem] = len(properties)
        
        return dict(models)
    
    def _analyze_viewmodels(self) -> Dict:
        """Analyse les ViewModels"""
        viewmodels_path = self.ios_path / "ViewModels"
        viewmodels = {
            "count": 0,
            "list": [],
            "published_properties": defaultdict(int),
            "methods": defaultdict(int)
        }
        
        if not viewmodels_path.exists():
            return viewmodels
        
        for vm_file in viewmodels_path.glob("*.swift"):
            viewmodels["count"] += 1
            viewmodels["list"].append(vm_file.stem)
            
            content = vm_file.read_text(encoding='utf-8', errors='ignore')
            
            # Compter les propriétés @Published
            published = len(re.findall(r'@Published', content))
            viewmodels["published_properties"][vm_file.stem] = published
            
            # Compter les méthodes
            methods = len(re.findall(r'func\s+\w+', content))
            viewmodels["methods"][vm_file.stem] = methods
        
        return dict(viewmodels)
    
    def _analyze_patterns(self) -> Dict:
        """Analyse les patterns architecturaux"""
        patterns = {
            "mvvm": False,
            "singleton": False,
            "observer": False,
            "factory": False,
            "repository": False
        }
        
        # Analyser les fichiers pour détecter les patterns
        ios_files = list(self.ios_path.rglob("*.swift"))
        
        for file_path in ios_files[:50]:  # Limiter pour performance
            try:
                content = file_path.read_text(encoding='utf-8', errors='ignore')
                
                # MVVM
                if "@StateObject" in content or "@ObservedObject" in content:
                    patterns["mvvm"] = True
                
                # Singleton
                if "static let shared" in content:
                    patterns["singleton"] = True
                
                # Observer
                if "@Published" in content or "Combine" in content:
                    patterns["observer"] = True
                
                # Factory
                if "Factory" in content and "static func" in content:
                    patterns["factory"] = True
                
                # Repository (moins commun en iOS)
                if "Repository" in content:
                    patterns["repository"] = True
            except:
                continue
        
        return patterns
    
    def _analyze_dependencies(self) -> Dict:
        """Analyse les dépendances externes"""
        dependencies = {
            "frameworks": [],
            "packages": []
        }
        
        # Chercher Package.swift ou project.pbxproj
        project_file = self.project_path / "Tshiakani VTC.xcodeproj" / "project.pbxproj"
        
        if project_file.exists():
            content = project_file.read_text(encoding='utf-8', errors='ignore')
            
            # Détecter les frameworks
            frameworks = re.findall(r'(\w+\.framework)', content)
            dependencies["frameworks"] = list(set(frameworks))
            
            # Détecter les packages Swift
            packages = re.findall(r'packageProductDependency.*?name = "(\w+)"', content)
            dependencies["packages"] = list(set(packages))
        
        return dependencies
    
    def _analyze_code_quality(self) -> Dict:
        """Analyse la qualité du code"""
        quality = {
            "total_files": 0,
            "total_lines": 0,
            "average_lines_per_file": 0,
            "complexity": "medium",
            "documentation": 0
        }
        
        swift_files = list(self.ios_path.rglob("*.swift"))
        quality["total_files"] = len(swift_files)
        
        total_lines = 0
        documented_files = 0
        
        for file_path in swift_files[:100]:  # Limiter pour performance
            try:
                content = file_path.read_text(encoding='utf-8', errors='ignore')
                lines = len(content.splitlines())
                total_lines += lines
                
                # Vérifier la documentation
                if "///" in content or "/**" in content:
                    documented_files += 1
            except:
                continue
        
        quality["total_lines"] = total_lines
        if quality["total_files"] > 0:
            quality["average_lines_per_file"] = total_lines / quality["total_files"]
            quality["documentation"] = (documented_files / quality["total_files"]) * 100
        
        return quality
    
    def _calculate_metrics(self) -> Dict:
        """Calcule les métriques iOS"""
        metrics = {
            "services_count": len(list((self.ios_path / "Services").glob("*.swift")) if (self.ios_path / "Services").exists() else []),
            "views_count": len(list((self.ios_path / "Views").rglob("*.swift")) if (self.ios_path / "Views").exists() else []),
            "models_count": len(list((self.ios_path / "Models").glob("*.swift")) if (self.ios_path / "Models").exists() else []),
            "viewmodels_count": len(list((self.ios_path / "ViewModels").glob("*.swift")) if (self.ios_path / "ViewModels").exists() else [])
        }
        return metrics

class BackendAnalyzer:
    """Analyseur pour le backend Node.js"""
    
    def __init__(self, project_path: Path):
        self.project_path = project_path
        self.backend_path = project_path / "backend"
    
    def analyze(self) -> Dict:
        """Analyse complète de l'architecture backend"""
        analysis = {
            "structure": self._analyze_structure(),
            "routes": self._analyze_routes(),
            "services": self._analyze_services(),
            "middlewares": self._analyze_middlewares(),
            "entities": self._analyze_entities(),
            "database": self._analyze_database(),
            "dependencies": self._analyze_dependencies(),
            "security": self._analyze_security(),
            "code_quality": self._analyze_code_quality(),
            "metrics": self._calculate_metrics()
        }
        return analysis
    
    def _analyze_structure(self) -> Dict:
        """Analyse la structure du backend"""
        structure = {
            "routes": [],
            "services": [],
            "middlewares": [],
            "entities": [],
            "models": [],
            "utils": [],
            "config": []
        }
        
        if not self.backend_path.exists():
            return structure
        
        # Routes
        routes_path = self.backend_path / "routes.postgres"
        if routes_path.exists():
            structure["routes"] = [f.name for f in routes_path.glob("*.js")]
        
        # Services
        services_path = self.backend_path / "services"
        if services_path.exists():
            structure["services"] = [f.name for f in services_path.glob("*.js")]
        
        # Middlewares
        middlewares_path = self.backend_path / "middlewares.postgres"
        if middlewares_path.exists():
            structure["middlewares"] = [f.name for f in middlewares_path.glob("*.js")]
        
        # Entities
        entities_path = self.backend_path / "entities"
        if entities_path.exists():
            structure["entities"] = [f.name for f in entities_path.glob("*.js")]
        
        # Models
        models_path = self.backend_path / "models"
        if models_path.exists():
            structure["models"] = [f.name for f in models_path.glob("*.js")]
        
        # Utils
        utils_path = self.backend_path / "utils"
        if utils_path.exists():
            structure["utils"] = [f.name for f in utils_path.glob("*.js")]
        
        # Config
        config_path = self.backend_path / "config"
        if config_path.exists():
            structure["config"] = [f.name for f in config_path.glob("*.js")]
        
        return structure
    
    def _analyze_routes(self) -> Dict:
        """Analyse les routes API"""
        routes_path = self.backend_path / "routes.postgres"
        routes = {
            "count": 0,
            "endpoints": [],
            "methods": defaultdict(int),
            "protected": []
        }
        
        if not routes_path.exists():
            return routes
        
        for route_file in routes_path.glob("*.js"):
            routes["count"] += 1
            
            try:
                content = route_file.read_text(encoding='utf-8', errors='ignore')
                
                # Détecter les méthodes HTTP
                methods = re.findall(r'(app\.|router\.)(get|post|put|delete|patch)', content, re.IGNORECASE)
                for method in methods:
                    routes["methods"][method[1].upper()] += 1
                
                # Détecter les routes protégées
                if "auth" in content or "requireAuth" in content or "verifyToken" in content:
                    routes["protected"].append(route_file.stem)
                
                # Extraire les endpoints
                endpoints = re.findall(r'(get|post|put|delete|patch)\s*\([\'"](\/api\/[^\'"]+)', content, re.IGNORECASE)
                for method, endpoint in endpoints:
                    routes["endpoints"].append(f"{method.upper()} {endpoint}")
            except:
                continue
        
        return dict(routes)
    
    def _analyze_services(self) -> Dict:
        """Analyse les services backend"""
        services_path = self.backend_path / "services"
        services = {
            "count": 0,
            "list": [],
            "patterns": [],
            "async_methods": defaultdict(int)
        }
        
        if not services_path.exists():
            return services
        
        for service_file in services_path.glob("*.js"):
            services["count"] += 1
            services["list"].append(service_file.stem)
            
            try:
                content = service_file.read_text(encoding='utf-8', errors='ignore')
                
                # Détecter les méthodes async
                async_methods = len(re.findall(r'async\s+(\w+)', content))
                services["async_methods"][service_file.stem] = async_methods
                
                # Détecter les patterns
                if "class" in content:
                    services["patterns"].append("Class-based")
                if "module.exports" in content:
                    services["patterns"].append("Module exports")
            except:
                continue
        
        return dict(services)
    
    def _analyze_middlewares(self) -> Dict:
        """Analyse les middlewares"""
        middlewares_path = self.backend_path / "middlewares.postgres"
        middlewares = {
            "count": 0,
            "list": [],
            "types": []
        }
        
        if not middlewares_path.exists():
            return middlewares
        
        for middleware_file in middlewares_path.glob("*.js"):
            middlewares["count"] += 1
            middlewares["list"].append(middleware_file.stem)
            
            try:
                content = middleware_file.read_text(encoding='utf-8', errors='ignore')
                
                if "auth" in middleware_file.stem.lower():
                    middlewares["types"].append("Authentication")
                elif "geo" in middleware_file.stem.lower():
                    middlewares["types"].append("Geofencing")
                elif "rate" in middleware_file.stem.lower():
                    middlewares["types"].append("Rate Limiting")
                else:
                    middlewares["types"].append("Custom")
            except:
                continue
        
        return middlewares
    
    def _analyze_entities(self) -> Dict:
        """Analyse les entités TypeORM"""
        entities_path = self.backend_path / "entities"
        entities = {
            "count": 0,
            "list": [],
            "relations": defaultdict(int)
        }
        
        if not entities_path.exists():
            return entities
        
        for entity_file in entities_path.glob("*.js"):
            entities["count"] += 1
            entities["list"].append(entity_file.stem)
            
            try:
                content = entity_file.read_text(encoding='utf-8', errors='ignore')
                
                # Compter les relations
                relations = len(re.findall(r'@(OneToMany|ManyToOne|ManyToMany|OneToOne)', content))
                entities["relations"][entity_file.stem] = relations
            except:
                continue
        
        return dict(entities)
    
    def _analyze_database(self) -> Dict:
        """Analyse la configuration de la base de données"""
        database = {
            "type": "PostgreSQL",
            "orm": "TypeORM",
            "postgis": False,
            "migrations": []
        }
        
        # Vérifier PostGIS
        config_file = self.backend_path / "config" / "database.js"
        if config_file.exists():
            try:
                content = config_file.read_text(encoding='utf-8', errors='ignore')
                if "postgis" in content.lower() or "PostGIS" in content:
                    database["postgis"] = True
            except:
                pass
        
        # Analyser les migrations
        migrations_path = self.backend_path / "migrations"
        if migrations_path.exists():
            database["migrations"] = [f.name for f in migrations_path.glob("*.sql")]
        
        return database
    
    def _analyze_dependencies(self) -> Dict:
        """Analyse les dépendances npm"""
        package_file = self.backend_path / "package.json"
        dependencies = {
            "production": {},
            "development": {},
            "total": 0
        }
        
        if package_file.exists():
            try:
                with open(package_file, 'r', encoding='utf-8') as f:
                    package_data = json.load(f)
                
                dependencies["production"] = package_data.get("dependencies", {})
                dependencies["development"] = package_data.get("devDependencies", {})
                dependencies["total"] = len(dependencies["production"]) + len(dependencies["development"])
            except:
                pass
        
        return dependencies
    
    def _analyze_security(self) -> Dict:
        """Analyse la sécurité"""
        security = {
            "jwt": False,
            "helmet": False,
            "rate_limiting": False,
            "cors": False,
            "bcrypt": False,
            "validation": False
        }
        
        # Analyser server.postgres.js
        server_file = self.backend_path / "server.postgres.js"
        if server_file.exists():
            try:
                content = server_file.read_text(encoding='utf-8', errors='ignore')
                
                security["jwt"] = "jsonwebtoken" in content or "jwt" in content.lower()
                security["helmet"] = "helmet" in content.lower()
                security["rate_limiting"] = "rateLimit" in content or "rate-limit" in content
                security["cors"] = "cors" in content.lower()
                security["bcrypt"] = "bcrypt" in content.lower()
                security["validation"] = "validator" in content.lower() or "express-validator" in content
            except:
                pass
        
        return security
    
    def _analyze_code_quality(self) -> Dict:
        """Analyse la qualité du code"""
        quality = {
            "total_files": 0,
            "total_lines": 0,
            "average_lines_per_file": 0,
            "documentation": 0,
            "error_handling": False
        }
        
        js_files = list(self.backend_path.rglob("*.js"))
        quality["total_files"] = len(js_files)
        
        total_lines = 0
        documented_files = 0
        error_handling_files = 0
        
        for file_path in js_files[:100]:  # Limiter pour performance
            try:
                content = file_path.read_text(encoding='utf-8', errors='ignore')
                lines = len(content.splitlines())
                total_lines += lines
                
                # Vérifier la documentation
                if "///" in content or "/**" in content or "/*" in content:
                    documented_files += 1
                
                # Vérifier la gestion d'erreurs
                if "try" in content and "catch" in content:
                    error_handling_files += 1
            except:
                continue
        
        quality["total_lines"] = total_lines
        if quality["total_files"] > 0:
            quality["average_lines_per_file"] = total_lines / quality["total_files"]
            quality["documentation"] = (documented_files / quality["total_files"]) * 100
            quality["error_handling"] = (error_handling_files / quality["total_files"]) > 0.5
        
        return quality
    
    def _calculate_metrics(self) -> Dict:
        """Calcule les métriques backend"""
        metrics = {
            "routes_count": len(list((self.backend_path / "routes.postgres").glob("*.js")) if (self.backend_path / "routes.postgres").exists() else []),
            "services_count": len(list((self.backend_path / "services").glob("*.js")) if (self.backend_path / "services").exists() else []),
            "entities_count": len(list((self.backend_path / "entities").glob("*.js")) if (self.backend_path / "entities").exists() else []),
            "middlewares_count": len(list((self.backend_path / "middlewares.postgres").glob("*.js")) if (self.backend_path / "middlewares.postgres").exists() else [])
        }
        return metrics

class DashboardAnalyzer:
    """Analyseur pour le dashboard Admin (React)"""
    
    def __init__(self, project_path: Path):
        self.project_path = project_path
        self.dashboard_path = project_path / "admin-dashboard"
    
    def analyze(self) -> Dict:
        """Analyse complète de l'architecture dashboard"""
        analysis = {
            "structure": self._analyze_structure(),
            "components": self._analyze_components(),
            "pages": self._analyze_pages(),
            "services": self._analyze_services(),
            "dependencies": self._analyze_dependencies(),
            "code_quality": self._analyze_code_quality(),
            "metrics": self._calculate_metrics()
        }
        return analysis
    
    def _analyze_structure(self) -> Dict:
        """Analyse la structure du dashboard"""
        structure = {
            "components": [],
            "pages": [],
            "services": [],
            "utils": []
        }
        
        if not self.dashboard_path.exists():
            return structure
        
        src_path = self.dashboard_path / "src"
        if not src_path.exists():
            return structure
        
        # Components
        components_path = src_path / "components"
        if components_path.exists():
            structure["components"] = [f.name for f in components_path.rglob("*.jsx")]
        
        # Pages
        pages_path = src_path / "pages"
        if pages_path.exists():
            structure["pages"] = [f.name for f in pages_path.rglob("*.jsx")]
        
        # Services
        services_path = src_path / "services"
        if services_path.exists():
            structure["services"] = [f.name for f in services_path.rglob("*.js")]
        
        # Utils
        utils_path = src_path / "utils"
        if utils_path.exists():
            structure["utils"] = [f.name for f in utils_path.rglob("*.js")]
        
        return structure
    
    def _analyze_components(self) -> Dict:
        """Analyse les composants React"""
        components_path = self.dashboard_path / "src" / "components"
        components = {
            "count": 0,
            "list": [],
            "hooks": []
        }
        
        if not components_path.exists():
            return components
        
        for component_file in components_path.rglob("*.jsx"):
            components["count"] += 1
            components["list"].append(str(component_file.relative_to(self.dashboard_path)))
            
            try:
                content = component_file.read_text(encoding='utf-8', errors='ignore')
                
                # Détecter les hooks
                hooks = re.findall(r'use(\w+)', content)
                components["hooks"].extend(hooks)
            except:
                continue
        
        return components
    
    def _analyze_pages(self) -> Dict:
        """Analyse les pages"""
        pages_path = self.dashboard_path / "src" / "pages"
        pages = {
            "count": 0,
            "list": []
        }
        
        if not pages_path.exists():
            return pages
        
        for page_file in pages_path.rglob("*.jsx"):
            pages["count"] += 1
            pages["list"].append(page_file.stem)
        
        return pages
    
    def _analyze_services(self) -> Dict:
        """Analyse les services"""
        services_path = self.dashboard_path / "src" / "services"
        services = {
            "count": 0,
            "list": [],
            "api_calls": []
        }
        
        if not services_path.exists():
            return services
        
        for service_file in services_path.rglob("*.js"):
            services["count"] += 1
            services["list"].append(service_file.stem)
            
            try:
                content = service_file.read_text(encoding='utf-8', errors='ignore')
                
                # Détecter les appels API
                api_calls = re.findall(r'(fetch|axios|\.get|\.post|\.put|\.delete)', content)
                services["api_calls"].extend(api_calls)
            except:
                continue
        
        return services
    
    def _analyze_dependencies(self) -> Dict:
        """Analyse les dépendances npm"""
        package_file = self.dashboard_path / "package.json"
        dependencies = {
            "production": {},
            "development": {},
            "total": 0
        }
        
        if package_file.exists():
            try:
                with open(package_file, 'r', encoding='utf-8') as f:
                    package_data = json.load(f)
                
                dependencies["production"] = package_data.get("dependencies", {})
                dependencies["development"] = package_data.get("devDependencies", {})
                dependencies["total"] = len(dependencies["production"]) + len(dependencies["development"])
            except:
                pass
        
        return dependencies
    
    def _analyze_code_quality(self) -> Dict:
        """Analyse la qualité du code"""
        quality = {
            "total_files": 0,
            "total_lines": 0,
            "average_lines_per_file": 0,
            "documentation": 0
        }
        
        js_files = list((self.dashboard_path / "src").rglob("*.{js,jsx}")) if (self.dashboard_path / "src").exists() else []
        quality["total_files"] = len(js_files)
        
        total_lines = 0
        documented_files = 0
        
        for file_path in js_files[:50]:  # Limiter pour performance
            try:
                content = file_path.read_text(encoding='utf-8', errors='ignore')
                lines = len(content.splitlines())
                total_lines += lines
                
                # Vérifier la documentation
                if "///" in content or "/**" in content or "/*" in content:
                    documented_files += 1
            except:
                continue
        
        quality["total_lines"] = total_lines
        if quality["total_files"] > 0:
            quality["average_lines_per_file"] = total_lines / quality["total_files"]
            quality["documentation"] = (documented_files / quality["total_files"]) * 100
        
        return quality
    
    def _calculate_metrics(self) -> Dict:
        """Calcule les métriques dashboard"""
        src_path = self.dashboard_path / "src"
        metrics = {
            "components_count": len(list((src_path / "components").rglob("*.jsx")) if (src_path / "components").exists() else []),
            "pages_count": len(list((src_path / "pages").rglob("*.jsx")) if (src_path / "pages").exists() else []),
            "services_count": len(list((src_path / "services").rglob("*.js")) if (src_path / "services").exists() else [])
        }
        return metrics

class RecommendationEngine:
    """Moteur de recommandations architecturales"""
    
    def __init__(self):
        self.recommendations = []
    
    def generate_recommendations(self, ios_analysis: Dict, backend_analysis: Dict, dashboard_analysis: Dict) -> List[Dict]:
        """Génère des recommandations basées sur l'analyse"""
        recommendations = []
        
        # Recommandations iOS
        recommendations.extend(self._ios_recommendations(ios_analysis))
        
        # Recommandations Backend
        recommendations.extend(self._backend_recommendations(backend_analysis))
        
        # Recommandations Dashboard
        recommendations.extend(self._dashboard_recommendations(dashboard_analysis))
        
        # Recommandations globales
        recommendations.extend(self._global_recommendations(ios_analysis, backend_analysis, dashboard_analysis))
        
        return recommendations
    
    def _ios_recommendations(self, analysis: Dict) -> List[Dict]:
        """Recommandations pour iOS"""
        recommendations = []
        
        # Vérifier la documentation
        code_quality = analysis.get("code_quality", {})
        if code_quality.get("documentation", 0) < 50:
            recommendations.append({
                "category": "iOS",
                "priority": "medium",
                "title": "Améliorer la documentation du code iOS",
                "description": f"Seulement {code_quality.get('documentation', 0):.1f}% des fichiers sont documentés. Ajoutez des commentaires pour améliorer la maintenabilité.",
                "impact": "Maintenabilité"
            })
        
        # Vérifier les tests
        if not any("test" in str(f).lower() for f in Path(".").rglob("*.swift")):
            recommendations.append({
                "category": "iOS",
                "priority": "high",
                "title": "Ajouter des tests unitaires iOS",
                "description": "Aucun test unitaire détecté. Ajoutez des tests pour les ViewModels et Services critiques.",
                "impact": "Qualité"
            })
        
        # Vérifier les services
        services = analysis.get("services", {})
        if services.get("count", 0) > 15:
            recommendations.append({
                "category": "iOS",
                "priority": "low",
                "title": "Réorganiser les services",
                "description": f"{services.get('count', 0)} services détectés. Considérez regrouper les services liés.",
                "impact": "Organisation"
            })
        
        return recommendations
    
    def _backend_recommendations(self, analysis: Dict) -> List[Dict]:
        """Recommandations pour le backend"""
        recommendations = []
        
        # Vérifier la sécurité
        security = analysis.get("security", {})
        if not all([security.get("jwt"), security.get("helmet"), security.get("rate_limiting")]):
            recommendations.append({
                "category": "Backend",
                "priority": "high",
                "title": "Renforcer la sécurité",
                "description": "Certaines mesures de sécurité ne sont pas implémentées. Vérifiez JWT, Helmet et Rate Limiting.",
                "impact": "Sécurité"
            })
        
        # Vérifier la gestion d'erreurs
        code_quality = analysis.get("code_quality", {})
        if not code_quality.get("error_handling", False):
            recommendations.append({
                "category": "Backend",
                "priority": "high",
                "title": "Améliorer la gestion d'erreurs",
                "description": "La gestion d'erreurs pourrait être améliorée. Implémentez un middleware de gestion d'erreurs centralisé.",
                "impact": "Fiabilité"
            })
        
        # Vérifier les tests
        if not (Path("backend") / "__tests__").exists():
            recommendations.append({
                "category": "Backend",
                "priority": "high",
                "title": "Ajouter des tests backend",
                "description": "Aucun test backend détecté. Ajoutez des tests unitaires et d'intégration.",
                "impact": "Qualité"
            })
        
        # Vérifier PostGIS
        database = analysis.get("database", {})
        if not database.get("postgis", False):
            recommendations.append({
                "category": "Backend",
                "priority": "medium",
                "title": "Vérifier la configuration PostGIS",
                "description": "PostGIS n'est pas détecté dans la configuration. Vérifiez que PostGIS est bien configuré pour la géolocalisation.",
                "impact": "Fonctionnalité"
            })
        
        return recommendations
    
    def _dashboard_recommendations(self, analysis: Dict) -> List[Dict]:
        """Recommandations pour le dashboard"""
        recommendations = []
        
        # Vérifier la documentation
        code_quality = analysis.get("code_quality", {})
        if code_quality.get("documentation", 0) < 30:
            recommendations.append({
                "category": "Dashboard",
                "priority": "low",
                "title": "Améliorer la documentation React",
                "description": f"Seulement {code_quality.get('documentation', 0):.1f}% des fichiers sont documentés.",
                "impact": "Maintenabilité"
            })
        
        return recommendations
    
    def _global_recommendations(self, ios_analysis: Dict, backend_analysis: Dict, dashboard_analysis: Dict) -> List[Dict]:
        """Recommandations globales"""
        recommendations = []
        
        # Monitoring
        recommendations.append({
            "category": "Global",
            "priority": "high",
            "title": "Implémenter le monitoring",
            "description": "Ajoutez un système de monitoring (ex: Winston pour les logs, Prometheus pour les métriques).",
            "impact": "Observabilité"
        })
        
        # CI/CD
        if not Path(".github/workflows").exists() and not Path(".gitlab-ci.yml").exists():
            recommendations.append({
                "category": "Global",
                "priority": "medium",
                "title": "Configurer CI/CD",
                "description": "Configurez un pipeline CI/CD pour automatiser les tests et le déploiement.",
                "impact": "DevOps"
            })
        
        # Documentation API
        if not (Path("backend") / "swagger.json").exists():
            recommendations.append({
                "category": "Global",
                "priority": "medium",
                "title": "Documenter l'API",
                "description": "Ajoutez la documentation Swagger/OpenAPI pour l'API backend.",
                "impact": "Documentation"
            })
        
        return recommendations

class AgentArchitectePrincipal:
    """Agent Architecte Principal - Système d'analyse architecturale"""
    
    def __init__(self, project_path: str = "."):
        self.project_path = Path(project_path)
        self.ios_analyzer = IOSAnalyzer(self.project_path)
        self.backend_analyzer = BackendAnalyzer(self.project_path)
        self.dashboard_analyzer = DashboardAnalyzer(self.project_path)
        self.recommendation_engine = RecommendationEngine()
    
    def analyze(self) -> ArchitectureReport:
        """Effectue une analyse complète de l'architecture"""
        print("🏛️ Analyse de l'architecture en cours...")
        
        # Analyser iOS
        print("  📱 Analyse iOS...")
        ios_analysis = self.ios_analyzer.analyze()
        
        # Analyser Backend
        print("  🔧 Analyse Backend...")
        backend_analysis = self.backend_analyzer.analyze()
        
        # Analyser Dashboard
        print("  🎨 Analyse Dashboard...")
        dashboard_analysis = self.dashboard_analyzer.analyze()
        
        # Générer les recommandations
        print("  💡 Génération des recommandations...")
        recommendations = self.recommendation_engine.generate_recommendations(
            ios_analysis, backend_analysis, dashboard_analysis
        )
        
        # Calculer le score de qualité
        quality_score = self._calculate_quality_score(
            ios_analysis, backend_analysis, dashboard_analysis
        )
        
        # Créer le rapport
        report = ArchitectureReport(
            timestamp=datetime.now().isoformat(),
            version="1.0.0",
            ios_analysis=ios_analysis,
            backend_analysis=backend_analysis,
            dashboard_analysis=dashboard_analysis,
            recommendations=recommendations,
            metrics=self._calculate_global_metrics(ios_analysis, backend_analysis, dashboard_analysis),
            quality_score=quality_score
        )
        
        return report
    
    def _calculate_quality_score(self, ios_analysis: Dict, backend_analysis: Dict, dashboard_analysis: Dict) -> float:
        """Calcule un score de qualité global (0-100)"""
        score = 0.0
        factors = 0
        
        # iOS
        ios_quality = ios_analysis.get("code_quality", {})
        if ios_quality.get("documentation", 0) > 0:
            score += min(ios_quality.get("documentation", 0) / 100 * 25, 25)
            factors += 25
        
        # Backend
        backend_quality = backend_analysis.get("code_quality", {})
        if backend_quality.get("documentation", 0) > 0:
            score += min(backend_quality.get("documentation", 0) / 100 * 25, 25)
            factors += 25
        
        backend_security = backend_analysis.get("security", {})
        security_count = sum([1 for v in backend_security.values() if v])
        if security_count > 0:
            score += (security_count / 6) * 25
            factors += 25
        
        # Dashboard
        dashboard_quality = dashboard_analysis.get("code_quality", {})
        if dashboard_quality.get("documentation", 0) > 0:
            score += min(dashboard_quality.get("documentation", 0) / 100 * 25, 25)
            factors += 25
        
        return score if factors > 0 else 0.0
    
    def _calculate_global_metrics(self, ios_analysis: Dict, backend_analysis: Dict, dashboard_analysis: Dict) -> Dict:
        """Calcule les métriques globales"""
        return {
            "total_ios_files": ios_analysis.get("code_quality", {}).get("total_files", 0),
            "total_backend_files": backend_analysis.get("code_quality", {}).get("total_files", 0),
            "total_dashboard_files": dashboard_analysis.get("code_quality", {}).get("total_files", 0),
            "total_recommendations": len(self.recommendation_engine.recommendations) if hasattr(self.recommendation_engine, 'recommendations') else 0
        }
    
    def generate_report(self, report: ArchitectureReport, output_file: Optional[str] = None) -> str:
        """Génère un rapport Markdown"""
        if output_file is None:
            output_file = f"RAPPORT_ARCHITECTURE_{datetime.now().strftime('%Y%m%d_%H%M%S')}.md"
        
        output_path = self.project_path / output_file
        
        markdown = f"""# 🏛️ Rapport d'Architecture - Tshiakani VTC

**Date**: {report.timestamp}  
**Version**: {report.version}  
**Score de Qualité**: {report.quality_score:.1f}/100

---

## 📊 Résumé Exécutif

### Métriques Globales
- **Fichiers iOS**: {report.metrics.get('total_ios_files', 0)}
- **Fichiers Backend**: {report.metrics.get('total_backend_files', 0)}
- **Fichiers Dashboard**: {report.metrics.get('total_dashboard_files', 0)}
- **Recommandations**: {len(report.recommendations)}

### Score de Qualité
**{report.quality_score:.1f}/100** - {'Excellent' if report.quality_score >= 80 else 'Bon' if report.quality_score >= 60 else 'Moyen' if report.quality_score >= 40 else 'À améliorer'}

---

## 📱 Analyse iOS

### Structure
- **Services**: {report.ios_analysis.get('metrics', {}).get('services_count', 0)}
- **Vues**: {report.ios_analysis.get('metrics', {}).get('views_count', 0)}
- **Modèles**: {report.ios_analysis.get('metrics', {}).get('models_count', 0)}
- **ViewModels**: {report.ios_analysis.get('metrics', {}).get('viewmodels_count', 0)}

### Patterns Détectés
{self._format_patterns(report.ios_analysis.get('patterns', {}))}

### Qualité du Code
- **Fichiers**: {report.ios_analysis.get('code_quality', {}).get('total_files', 0)}
- **Lignes**: {report.ios_analysis.get('code_quality', {}).get('total_lines', 0)}
- **Documentation**: {report.ios_analysis.get('code_quality', {}).get('documentation', 0):.1f}%

---

## 🔧 Analyse Backend

### Structure
- **Routes**: {report.backend_analysis.get('metrics', {}).get('routes_count', 0)}
- **Services**: {report.backend_analysis.get('metrics', {}).get('services_count', 0)}
- **Entities**: {report.backend_analysis.get('metrics', {}).get('entities_count', 0)}
- **Middlewares**: {report.backend_analysis.get('metrics', {}).get('middlewares_count', 0)}

### Sécurité
{self._format_security(report.backend_analysis.get('security', {}))}

### Base de Données
- **Type**: {report.backend_analysis.get('database', {}).get('type', 'N/A')}
- **ORM**: {report.backend_analysis.get('database', {}).get('orm', 'N/A')}
- **PostGIS**: {'✅ Oui' if report.backend_analysis.get('database', {}).get('postgis', False) else '❌ Non'}

### Qualité du Code
- **Fichiers**: {report.backend_analysis.get('code_quality', {}).get('total_files', 0)}
- **Lignes**: {report.backend_analysis.get('code_quality', {}).get('total_lines', 0)}
- **Documentation**: {report.backend_analysis.get('code_quality', {}).get('documentation', 0):.1f}%
- **Gestion d'erreurs**: {'✅ Oui' if report.backend_analysis.get('code_quality', {}).get('error_handling', False) else '❌ Non'}

---

## 🎨 Analyse Dashboard

### Structure
- **Composants**: {report.dashboard_analysis.get('metrics', {}).get('components_count', 0)}
- **Pages**: {report.dashboard_analysis.get('metrics', {}).get('pages_count', 0)}
- **Services**: {report.dashboard_analysis.get('metrics', {}).get('services_count', 0)}

### Qualité du Code
- **Fichiers**: {report.dashboard_analysis.get('code_quality', {}).get('total_files', 0)}
- **Lignes**: {report.dashboard_analysis.get('code_quality', {}).get('total_lines', 0)}
- **Documentation**: {report.dashboard_analysis.get('code_quality', {}).get('documentation', 0):.1f}%

---

## 💡 Recommandations

"""
        
        # Grouper les recommandations par priorité
        high_priority = [r for r in report.recommendations if r.get('priority') == 'high']
        medium_priority = [r for r in report.recommendations if r.get('priority') == 'medium']
        low_priority = [r for r in report.recommendations if r.get('priority') == 'low']
        
        if high_priority:
            markdown += "### 🔴 Priorité Haute\n\n"
            for rec in high_priority:
                markdown += f"- **[{rec.get('category')}]** {rec.get('title')}\n"
                markdown += f"  - {rec.get('description')}\n"
                markdown += f"  - Impact: {rec.get('impact')}\n\n"
        
        if medium_priority:
            markdown += "### 🟡 Priorité Moyenne\n\n"
            for rec in medium_priority:
                markdown += f"- **[{rec.get('category')}]** {rec.get('title')}\n"
                markdown += f"  - {rec.get('description')}\n"
                markdown += f"  - Impact: {rec.get('impact')}\n\n"
        
        if low_priority:
            markdown += "### 🟢 Priorité Basse\n\n"
            for rec in low_priority:
                markdown += f"- **[{rec.get('category')}]** {rec.get('title')}\n"
                markdown += f"  - {rec.get('description')}\n"
                markdown += f"  - Impact: {rec.get('impact')}\n\n"
        
        markdown += """---

## 📈 Prochaines Étapes

1. **Réviser les recommandations prioritaires**
2. **Implémenter les améliorations de sécurité**
3. **Ajouter les tests manquants**
4. **Améliorer la documentation**
5. **Configurer le monitoring**

---

**Généré par**: Agent Architecte Principal  
**Date**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

"""
        
        output_path.write_text(markdown, encoding='utf-8')
        return str(output_path)
    
    def _format_patterns(self, patterns: Dict) -> str:
        """Formate les patterns détectés"""
        formatted = []
        for pattern, detected in patterns.items():
            status = "✅" if detected else "❌"
            formatted.append(f"- **{pattern}**: {status}")
        return "\n".join(formatted)
    
    def _format_security(self, security: Dict) -> str:
        """Formate les mesures de sécurité"""
        formatted = []
        for measure, enabled in security.items():
            status = "✅" if enabled else "❌"
            formatted.append(f"- **{measure}**: {status}")
        return "\n".join(formatted)
    
    def generate_json_report(self, report: ArchitectureReport, output_file: Optional[str] = None) -> str:
        """Génère un rapport JSON"""
        if output_file is None:
            output_file = f"RAPPORT_ARCHITECTURE_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        output_path = self.project_path / output_file
        report_dict = asdict(report)
        
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(report_dict, f, indent=2, ensure_ascii=False)
        
        return str(output_path)

def main():
    """Point d'entrée principal"""
    import sys
    
    project_path = sys.argv[1] if len(sys.argv) > 1 else "."
    
    print("🏛️ Agent Architecte Principal - Tshiakani VTC")
    print("=" * 60)
    
    agent = AgentArchitectePrincipal(project_path)
    report = agent.analyze()
    
    # Générer les rapports
    print("\n📄 Génération des rapports...")
    markdown_file = agent.generate_report(report)
    json_file = agent.generate_json_report(report)
    
    print(f"\n✅ Rapport Markdown généré: {markdown_file}")
    print(f"✅ Rapport JSON généré: {json_file}")
    print(f"\n📊 Score de Qualité: {report.quality_score:.1f}/100")
    print(f"💡 Recommandations: {len(report.recommendations)}")
    
    # Afficher les recommandations prioritaires
    high_priority = [r for r in report.recommendations if r.get('priority') == 'high']
    if high_priority:
        print(f"\n🔴 Recommandations Prioritaires ({len(high_priority)}):")
        for rec in high_priority[:5]:
            print(f"  - [{rec.get('category')}] {rec.get('title')}")

if __name__ == "__main__":
    main()

