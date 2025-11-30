#!/bin/bash

# Создание Institutions Module
cat > src/institutions/institutions.module.ts << 'EOF'
import { Module } from '@nestjs/common';
import { InstitutionsService } from './institutions.service';
import { InstitutionsController } from './institutions.controller';

@Module({
  providers: [InstitutionsService],
  controllers: [InstitutionsController],
  exports: [InstitutionsService],
})
export class InstitutionsModule {}
EOF

cat > src/institutions/institutions.service.ts << 'EOF'
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class InstitutionsService {
  constructor(private prisma: PrismaService) {}

  findAll() {
    return this.prisma.institution.findMany({
      where: { isActive: true },
      orderBy: { name: 'asc' },
    });
  }

  findOne(id: number) {
    return this.prisma.institution.findUnique({ where: { id } });
  }

  create(data: { name: string; code?: string; city?: string }) {
    return this.prisma.institution.create({ data });
  }

  update(id: number, data: { name?: string; code?: string; city?: string }) {
    return this.prisma.institution.update({ where: { id }, data });
  }

  remove(id: number) {
    return this.prisma.institution.update({
      where: { id },
      data: { isActive: false },
    });
  }
}
EOF

cat > src/institutions/institutions.controller.ts << 'EOF'
import { Controller, Get, Post, Put, Delete, Body, Param, ParseIntPipe, UseGuards } from '@nestjs/common';
import { InstitutionsService } from './institutions.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';

@Controller('institutions')
@UseGuards(JwtAuthGuard)
export class InstitutionsController {
  constructor(private service: InstitutionsService) {}

  @Get()
  findAll() {
    return this.service.findAll();
  }

  @Post()
  @UseGuards(RolesGuard)
  @Roles('admin')
  create(@Body() data: { name: string; code?: string; city?: string }) {
    return this.service.create(data);
  }

  @Put(':id')
  @UseGuards(RolesGuard)
  @Roles('admin')
  update(@Param('id', ParseIntPipe) id: number, @Body() data: any) {
    return this.service.update(id, data);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles('admin')
  remove(@Param('id', ParseIntPipe) id: number) {
    return this.service.remove(id);
  }
}
EOF

# Создание Dictionaries Module
cat > src/dictionaries/dictionaries.module.ts << 'EOF'
import { Module } from '@nestjs/common';
import { DictionariesService } from './dictionaries.service';
import { DictionariesController } from './dictionaries.controller';

@Module({
  providers: [DictionariesService],
  controllers: [DictionariesController],
  exports: [DictionariesService],
})
export class DictionariesModule {}
EOF

cat > src/dictionaries/dictionaries.service.ts << 'EOF'
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class DictionariesService {
  constructor(private prisma: PrismaService) {}

  findAll(category?: string) {
    return this.prisma.dictionary.findMany({
      where: category ? { category, isActive: true } : { isActive: true },
      orderBy: [{ category: 'asc' }, { sortOrder: 'asc' }],
    });
  }

  getCategories() {
    return this.prisma.dictionary.findMany({
      where: { isActive: true },
      distinct: ['category'],
      select: { category: true },
    });
  }

  create(data: any) {
    return this.prisma.dictionary.create({ data });
  }

  update(id: number, data: any) {
    return this.prisma.dictionary.update({ where: { id }, data });
  }

  remove(id: number) {
    return this.prisma.dictionary.update({
      where: { id },
      data: { isActive: false },
    });
  }
}
EOF

cat > src/dictionaries/dictionaries.controller.ts << 'EOF'
import { Controller, Get, Post, Put, Delete, Body, Param, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { DictionariesService } from './dictionaries.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';

@Controller('dictionaries')
@UseGuards(JwtAuthGuard)
export class DictionariesController {
  constructor(private service: DictionariesService) {}

  @Get()
  findAll(@Query('category') category?: string) {
    return this.service.findAll(category);
  }

  @Get('categories')
  getCategories() {
    return this.service.getCategories();
  }

  @Post()
  @UseGuards(RolesGuard)
  @Roles('admin')
  create(@Body() data: any) {
    return this.service.create(data);
  }

  @Put(':id')
  @UseGuards(RolesGuard)
  @Roles('admin')
  update(@Param('id', ParseIntPipe) id: number, @Body() data: any) {
    return this.service.update(id, data);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles('admin')
  remove(@Param('id', ParseIntPipe) id: number) {
    return this.service.remove(id);
  }
}
EOF

# Создание Patients Module
cat > src/patients/patients.module.ts << 'EOF'
import { Module } from '@nestjs/common';
import { PatientsService } from './patients.service';
import { PatientsController } from './patients.controller';

@Module({
  providers: [PatientsService],
  controllers: [PatientsController],
  exports: [PatientsService],
})
export class PatientsModule {}
EOF

cat > src/patients/patients.service.ts << 'EOF'
import { Injectable, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { User } from '@prisma/client';

@Injectable()
export class PatientsService {
  constructor(private prisma: PrismaService) {}

  async findAll(user: User, registryType?: string) {
    const where: any = { isActive: true };
    
    if (user.role !== 'admin') {
      where.institutionId = user.institutionId;
    }
    
    if (registryType) {
      where.registryType = registryType;
    }

    return this.prisma.patient.findMany({
      where,
      include: {
        clinicalRecord: true,
        institution: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(id: number, user: User) {
    const patient = await this.prisma.patient.findUnique({
      where: { id },
      include: {
        clinicalRecord: true,
        institution: true,
        therapyLines: true,
        progressionRecords: true,
      },
    });

    if (!patient) {
      throw new ForbiddenException('Пациент не найден');
    }

    if (user.role !== 'admin' && patient.institutionId !== user.institutionId) {
      throw new ForbiddenException('Доступ запрещен');
    }

    return patient;
  }

  async create(data: any, user: User) {
    return this.prisma.patient.create({
      data: {
        institutionId: user.institutionId,
        createdBy: user.id,
        registryType: data.registryType || 'ALK',
        clinicalRecord: {
          create: data.clinicalRecord || {},
        },
      },
      include: {
        clinicalRecord: true,
        institution: true,
      },
    });
  }

  async update(id: number, data: any, user: User) {
    const patient = await this.findOne(id, user);

    return this.prisma.patient.update({
      where: { id },
      data: {
        clinicalRecord: {
          update: data.clinicalRecord || {},
        },
      },
      include: {
        clinicalRecord: true,
        institution: true,
      },
    });
  }

  async remove(id: number, user: User) {
    await this.findOne(id, user);
    return this.prisma.patient.update({
      where: { id },
      data: { isActive: false },
    });
  }

  async getCompletion(id: number, user: User) {
    const patient = await this.findOne(id, user);
    const record = patient.clinicalRecord;

    if (!record) {
      return { filledFields: 0, totalFields: 0, completionPercentage: 0 };
    }

    const fields = [
      'patientCode', 'gender', 'birthDate', 'height', 'weight',
      'smokingStatus', 'initialDiagnosisDate', 'tnmStage', 'histology',
      'alkDiagnosisDate', 'ecogAtStart', 'currentStatus',
    ];

    let filled = 0;
    fields.forEach(field => {
      if (record[field] !== null && record[field] !== undefined) filled++;
    });

    const percentage = (filled / fields.length) * 100;

    return {
      filledFields: filled,
      totalFields: fields.length,
      completionPercentage: Math.round(percentage * 100) / 100,
    };
  }
}
EOF

cat > src/patients/patients.controller.ts << 'EOF'
import { Controller, Get, Post, Put, Delete, Body, Param, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { PatientsService } from './patients.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { GetUser } from '../auth/decorators/get-user.decorator';
import { User } from '@prisma/client';

@Controller('patients')
@UseGuards(JwtAuthGuard)
export class PatientsController {
  constructor(private service: PatientsService) {}

  @Get()
  findAll(@GetUser() user: User, @Query('registryType') registryType?: string) {
    return this.service.findAll(user, registryType);
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number, @GetUser() user: User) {
    return this.service.findOne(id, user);
  }

  @Get(':id/completion')
  getCompletion(@Param('id', ParseIntPipe) id: number, @GetUser() user: User) {
    return this.service.getCompletion(id, user);
  }

  @Post()
  create(@Body() data: any, @GetUser() user: User) {
    return this.service.create(data, user);
  }

  @Put(':id')
  update(@Param('id', ParseIntPipe) id: number, @Body() data: any, @GetUser() user: User) {
    return this.service.update(id, data, user);
  }

  @Delete(':id')
  remove(@Param('id', ParseIntPipe) id: number, @GetUser() user: User) {
    return this.service.remove(id, user);
  }
}
EOF

# Создание Dynamic Fields Module (упрощенная версия)
cat > src/dynamic-fields/dynamic-fields.module.ts << 'EOF'
import { Module } from '@nestjs/common';
import { DynamicFieldsService } from './dynamic-fields.service';
import { DynamicFieldsController } from './dynamic-fields.controller';

@Module({
  providers: [DynamicFieldsService],
  controllers: [DynamicFieldsController],
})
export class DynamicFieldsModule {}
EOF

cat > src/dynamic-fields/dynamic-fields.service.ts << 'EOF'
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class DynamicFieldsService {
  constructor(private prisma: PrismaService) {}

  findAll() {
    return this.prisma.dynamicField.findMany({
      where: { isActive: true },
      orderBy: [{ section: 'asc' }, { sortOrder: 'asc' }],
    });
  }

  create(data: any) {
    return this.prisma.dynamicField.create({ data });
  }

  update(id: number, data: any) {
    return this.prisma.dynamicField.update({ where: { id }, data });
  }

  remove(id: number) {
    return this.prisma.dynamicField.update({
      where: { id },
      data: { isActive: false },
    });
  }
}
EOF

cat > src/dynamic-fields/dynamic-fields.controller.ts << 'EOF'
import { Controller, Get, Post, Put, Delete, Body, Param, ParseIntPipe, UseGuards } from '@nestjs/common';
import { DynamicFieldsService } from './dynamic-fields.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';

@Controller('dynamic-fields')
@UseGuards(JwtAuthGuard)
export class DynamicFieldsController {
  constructor(private service: DynamicFieldsService) {}

  @Get()
  findAll() {
    return this.service.findAll();
  }

  @Post()
  @UseGuards(RolesGuard)
  @Roles('admin')
  create(@Body() data: any) {
    return this.service.create(data);
  }

  @Put(':id')
  @UseGuards(RolesGuard)
  @Roles('admin')
  update(@Param('id', ParseIntPipe) id: number, @Body() data: any) {
    return this.service.update(id, data);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles('admin')
  remove(@Param('id', ParseIntPipe) id: number) {
    return this.service.remove(id);
  }
}
EOF

# Создание Therapy Module
cat > src/therapy/therapy.module.ts << 'EOF'
import { Module } from '@nestjs/common';
import { TherapyService } from './therapy.service';
import { TherapyController } from './therapy.controller';

@Module({
  providers: [TherapyService],
  controllers: [TherapyController],
})
export class TherapyModule {}
EOF

cat > src/therapy/therapy.service.ts << 'EOF'
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class TherapyService {
  constructor(private prisma: PrismaService) {}

  getTherapyLines(patientId: number) {
    return this.prisma.therapyLine.findMany({
      where: { patientId },
      orderBy: { lineNumber: 'asc' },
    });
  }

  createTherapyLine(data: any) {
    return this.prisma.therapyLine.create({ data });
  }

  updateTherapyLine(id: number, data: any) {
    return this.prisma.therapyLine.update({ where: { id }, data });
  }

  getProgressionRecords(patientId: number) {
    return this.prisma.progressionRecord.findMany({
      where: { patientId },
      orderBy: { progressionDate: 'desc' },
    });
  }

  createProgressionRecord(data: any) {
    return this.prisma.progressionRecord.create({ data });
  }
}
EOF

cat > src/therapy/therapy.controller.ts << 'EOF'
import { Controller, Get, Post, Put, Body, Param, ParseIntPipe, UseGuards } from '@nestjs/common';
import { TherapyService } from './therapy.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('therapy')
@UseGuards(JwtAuthGuard)
export class TherapyController {
  constructor(private service: TherapyService) {}

  @Get('lines/:patientId')
  getTherapyLines(@Param('patientId', ParseIntPipe) patientId: number) {
    return this.service.getTherapyLines(patientId);
  }

  @Post('lines')
  createTherapyLine(@Body() data: any) {
    return this.service.createTherapyLine(data);
  }

  @Put('lines/:id')
  updateTherapyLine(@Param('id', ParseIntPipe) id: number, @Body() data: any) {
    return this.service.updateTherapyLine(id, data);
  }

  @Get('progression/:patientId')
  getProgressionRecords(@Param('patientId', ParseIntPipe) patientId: number) {
    return this.service.getProgressionRecords(patientId);
  }

  @Post('progression')
  createProgressionRecord(@Body() data: any) {
    return this.service.createProgressionRecord(data);
  }
}
EOF

# Создание Audit Module
cat > src/audit/audit.module.ts << 'EOF'
import { Module } from '@nestjs/common';
import { AuditService } from './audit.service';
import { AuditController } from './audit.controller';

@Module({
  providers: [AuditService],
  controllers: [AuditController],
  exports: [AuditService],
})
export class AuditModule {}
EOF

cat > src/audit/audit.service.ts << 'EOF'
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AuditService {
  constructor(private prisma: PrismaService) {}

  async log(data: {
    userId: number;
    action: string;
    recordType?: string;
    recordId?: number;
    details?: any;
  }) {
    return this.prisma.auditLog.create({ data });
  }

  async getLogs(userId?: number, limit = 100) {
    return this.prisma.auditLog.findMany({
      where: userId ? { userId } : {},
      include: { user: true },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
  }
}
EOF

cat > src/audit/audit.controller.ts << 'EOF'
import { Controller, Get, Query, ParseIntPipe, UseGuards } from '@nestjs/common';
import { AuditService } from './audit.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';

@Controller('audit')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
export class AuditController {
  constructor(private service: AuditService) {}

  @Get()
  getLogs(@Query('userId', ParseIntPipe) userId?: number, @Query('limit') limit?: number) {
    return this.service.getLogs(userId, limit);
  }
}
EOF

echo "✅ All modules created successfully!"
